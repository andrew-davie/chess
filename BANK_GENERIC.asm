
            NEWBANK GENERIC_BANK_1

    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

    #if 0
    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF
    #endif

STELLA_AUTODETECT .byte $85,$3e,$a9,$00 ; 3E

            CHECK_HALF_BANK_SIZE "GENERIC_BANK_1 (DECODE_LEVEL)"

;---------------------------------------------------------------------------------------------------
; ... the above is a (potentially) RAM-copied section -- the following is ROM-only.  Note that
; we do not configure a 1K boundary, as we con't really care when the above 'RAM'
; bank finishes.  Just continue on from where it left off...
;---------------------------------------------------------------------------------------------------

    DEF Cart_Init
    SUBROUTINE

                    lda #0
                    sta SWBCNT                      ; console I/O always set to INPUT
                    sta SWACNT                      ; set controller I/O to INPUT
                    sta HMCLR

    ; cleanup remains of title screen
                    sta GRP0
                    sta GRP1

                    lda #%00010000                  ; double width missile, double width player
                    sta NUSIZ0
                    sta NUSIZ1

                    lda #%100                       ; players/missiles BEHIND BG
                    sta CTRLPF

                    rts


;---------------------------------------------------------------------------------------------------

    DEF Resync
    SUBROUTINE

                    RESYNC
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartClearBoard
    SUBROUTINE

                    ldx #8
                    stx drawCount                   ; = bank

                    lda #-1
                    sta highlight_row

                    PHASE AI_ClearEachRow
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiClearEachRow
    SUBROUTINE

                    dec drawCount
                    bmi .bitmapCleared
                    ldy drawCount
                    jmp CallClear

.bitmapCleared

                    lda #63
                    sta drawPieceNumber

                    PHASE AI_DrawEntireBoard
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFB3
    SUBROUTINE

                    lda #BLANK
                    sta previousPiece

                    PHASE AI_EraseStartPiece
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiEraseStartPiece
    SUBROUTINE

                    lda toSquare
                    cmp fromSquare
                    ;beq .idleErase

                    lda #6                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE AI_WriteStartPieceBlank
.idleErase          rts


;---------------------------------------------------------------------------------------------------

    DEF aiWriteStartPieceBlank
    SUBROUTINE

    ; Flash the piece in-place preparatory to moving it.
    ; drawDelay = flash speed
    ; drawCount = # of flashes

                    lda drawDelay
                    beq deCount
                    dec drawDelay
                    rts

deCount

                    lda drawCount
                    beq flashDone
                    dec drawCount

                    lda #4
                    sta drawDelay                   ; "getting ready to move" flash

                    lda fromSquare
                    sta drawPieceNumber
                    jsr SAFE_CopySinglePiece        ; EOR-draw = flash
                    rts

flashDone           PHASE AI_MarchToTargetA
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDEB2
    SUBROUTINE

                    jsr SAFE_CopySinglePiece
                    dec drawPieceNumber
                    bmi .comp

                    PHASE AI_DrawEntireBoard
                    rts

.comp               PHASE AI_FlipBuffers
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB
    SUBROUTINE

    ; Draw the piece in the new square

                    lda fromSquare
                    sta drawPieceNumber
                    jsr SAFE_CopySinglePiece        ; draw the moving piece into the new square

                    lda #6                          ; snail trail delay
                    sta drawDelay

                    PHASE AI_MarchToTargetB
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFinalFlash
    SUBROUTINE

                    lda drawDelay
                    beq .deCount
                    dec drawDelay
                    rts

.deCount            lda drawCount
                    beq flashDone2
                    dec drawCount

                    lda #10
                    sta drawDelay               ; "getting ready to move" flash

                    lda fromSquare
                    sta drawPieceNumber
                    jsr SAFE_CopySinglePiece
                    rts

flashDone2          PHASE AI_SpecialMoveFixup
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CastleFixup
    SUBROUTINE

    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king


                    lda fromPiece
                    and #FLAG_CASTLE
                    beq .noCast                     ; NOT involved in castle!

                    ldx #4
                    lda toSquare
.findCast           dex
                    bmi .noCast
                    cmp KSquare,x
                    bne .findCast


                    lda RSquareEnd,x
                    sta toX12
                    lda RSquareStart64,x
                    sta fromSquare
                    lda RSquareEnd64,x
                    sta toSquare

                    ldy RSquareStart,x
                    sty fromX12

                    lda fromPiece
                    and #128
                    ora #ROOK                       ; preserve colour
                    sta fromPiece

                    PHASE AI_FB3
                    rts

.noCast

                    lda sideToMove
                    eor #128
                    sta sideToMove                  ; swap

                    ;bmi .skip                       ; not human's turn?

                    ;PHASE AI_Halt ;tmp SartMoveGen

.skip               rts


KSquare             .byte 2,6,58,62
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97
RSquareStart64      .byte 0,7,56,63
RSquareEnd64        .byte 3,5,59,61


;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    SUBROUTINE

    ; SAFE

                    ldy #7
.copyRowBanks       ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                    jsr SAFE_CopyShadowROMtoRAM
                    dey
                    bpl .copyRowBanks

    ; copy the BOARD/MOVES bank

                    ldy #RAMBANK_MOVES_RAM
                    ldx #MOVES
                    jsr SAFE_CopyShadowROMtoRAM     ; this auto-initialises Board too

    ; copy the PLY banks

                    lda #MAX_PLY
                    sta __plyBank
                    ldy #RAMBANK_PLY
                    sty currentPly
.copyPlyBanks       ldx #BANK_PLY
                    jsr SAFE_CopyShadowROMtoRAM
                    iny
                    dec __plyBank
                    bne .copyPlyBanks

                    rts


;---------------------------------------------------------------------------------------------------

            CHECK_BANK_SIZE "GENERIC_BANK_1 -- full 2K"
