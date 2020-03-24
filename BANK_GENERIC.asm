
            NEWBANK GENERIC_BANK_1

    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

#if 0
    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF
#endif

STELLA_AUTODETECT .byte $85,$3e,$a9,$00 ; 3E


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
                    sta cursorX12

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

                    lda #99
                    sta squareToDraw

                    PHASE AI_DrawEntireBoard
                    rts



;---------------------------------------------------------------------------------------------------

    DEF aiMoveIsSelected
    SUBROUTINE
    TAG MOVE_SELECTED (AI)


    ; Both computer and human have now seleted a move, and converge here


    ; fromPiece     piece doing the move
    ; fromSquare    starting square BASE64
    ; toSquare      ending square BASE64
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12


                    jsr AdjustMaterialPositionalValue


                    lda #BLANK
                    sta previousPiece


                    ;lda toSquare
                    ;cmp fromSquare
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

                    lda #READY_TO_MOVE_FLASH
                    sta drawDelay                   ; "getting ready to move" flash

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece             ; EOR-draw = flash
                    rts

flashDone           PHASE AI_MarchToTargetA
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawPart2
    SUBROUTINE

                    jsr CopySinglePiece

    DEF aiDrawPart3
    SUBROUTINE

                    dec squareToDraw
                    lda squareToDraw
                    cmp #22
                    bcc .comp

                    PHASE AI_DrawEntireBoard
                    rts

.comp               PHASE AI_FlipBuffers
                    rts



;---------------------------------------------------------------------------------------------------

    DEF aiMarchB
    SUBROUTINE

    ; Draw the piece in the new square

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece             ; draw the moving piece into the new square

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

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece
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
                    beq .exit                       ; NOT involved in castle!

                    ldx #4
                    lda fromX12                     ; *destination*
.findCast           dex
                    bmi .exit
                    cmp KSquare,x
                    bne .findCast

                    lda RSquareEnd,x
                    sta toX12
                    ldy RSquareStart,x
                    sty fromX12
                    sty originX12

                    lda fromPiece
                    and #128                        ; colour bit
                    ora #ROOK                       ; preserve colour
                    sta fromPiece

                    PHASE AI_MoveIsSelected

    ; in this siutation (castle, rook moving) we do not change sides yet!

                    rts

.exit               lda sideToMove
                    eor #128
                    sta sideToMove

                    NEGEVAL
                    rts


KSquare             .byte 24,28,94,98
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97


;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    SUBROUTINE

        VAR __plyBank, 1

    ; SAFE

                    ldy #7
.copyRowBanks       ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                    jsr CopyShadowROMtoRAM
                    dey
                    bpl .copyRowBanks

    ; copy the BOARD/MOVES bank

                    ldy #RAMBANK_MOVES_RAM
                    ldx #MOVES
                    jsr CopyShadowROMtoRAM     ; this auto-initialises Board too

    ; copy the PLY banks

                    lda #MAX_PLY
                    sta __plyBank
                    ldy #RAMBANK_PLY
                    sty currentPly
.copyPlyBanks       ldx #BANK_PLY
                    jsr CopyShadowROMtoRAM
                    iny
                    dec __plyBank
                    bne .copyPlyBanks

                    rts


;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "GENERIC_BANK_1"


;---------------------------------------------------------------------------------------------------

    include "piece_vectors.asm"

; include "gfx/BLACK_MARKER_on_BLACK_SQUARE_0.asm"
; include "gfx/BLACK_MARKER_on_BLACK_SQUARE_1.asm"
; include "gfx/BLACK_MARKER_on_BLACK_SQUARE_2.asm"
; include "gfx/BLACK_MARKER_on_BLACK_SQUARE_3.asm"
; include "gfx/BLACK_MARKER_on_WHITE_SQUARE_0.asm"
; include "gfx/BLACK_MARKER_on_WHITE_SQUARE_1.asm"
; include "gfx/BLACK_MARKER_on_WHITE_SQUARE_2.asm"
; include "gfx/BLACK_MARKER_on_WHITE_SQUARE_3.asm"

; include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_0.asm"
; include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_1.asm"
; include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_2.asm"
; include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_3.asm"
; include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_0.asm"
; include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_1.asm"
; include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_2.asm"
; include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_3.asm"

 include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_3.asm"
 include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_0.asm"
 include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_1.asm"
 include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_2.asm"
 include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_3.asm"

 include "gfx/WHITE_MARKER_on_BLACK_SQUARE_0.asm"
 include "gfx/WHITE_MARKER_on_BLACK_SQUARE_1.asm"
 include "gfx/WHITE_MARKER_on_BLACK_SQUARE_2.asm"
 include "gfx/WHITE_MARKER_on_BLACK_SQUARE_3.asm"
 include "gfx/WHITE_MARKER_on_WHITE_SQUARE_0.asm"
 include "gfx/WHITE_MARKER_on_WHITE_SQUARE_1.asm"
 include "gfx/WHITE_MARKER_on_WHITE_SQUARE_2.asm"

            CHECK_BANK_SIZE "GENERIC_BANK_1 -- full 2K"
