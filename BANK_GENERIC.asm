
            NEWBANK GENERIC_BANK_1

    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

    #if 0
    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF
    #endif

STELLA_AUTODETECT .byte $85,$3e,$a9,$00

            CHECK_HALF_BANK_SIZE "GENERIC_BANK_1 (DECODE_LEVEL)"

    ;------------------------------------------------------------------------------
    ; ... the above is a RAM-copied section -- the following is ROM-only.  Note that
    ; we do not configure a 1K boundary, as we con't really care when the above 'RAM'
    ; bank finishes.  Just continue on from where it left off...
    ;------------------------------------------------------------------------------

    DEF Cart_Init ; in GENERIC_BANK_1

    ; Note the variables from the title selection are incredibly transient an can be stomped
    ; at any time.  So they need to be used immediately.


    ; odd usage below is to prevent any possibility of variable stomping/assumptions

                lda #0
                sta SWBCNT                      ; console I/O always set to INPUT
                sta SWACNT                      ; set controller I/O to INPUT
                sta HMCLR

    ; cleanup remains of title screen
                sta GRP0
                sta GRP1

                lda #%00010000              ; 2     double width missile, double width player
                sta NUSIZ0                  ; 3
                sta NUSIZ1

                lda #%100                       ; players/missiles BEHIND BG
                sta CTRLPF

;                lda #$FF
;                sta BufferedJoystick

                ;lda #DIRECTION_BITS             ;???
                ;sta ManLastDirection

                ;lda #0
;                sta ObjStackPtr                 ; object stack index of last entry
;                sta ObjStackPtr+1
;                sta ObjStackNum
;                sta ObjIterator

                ;sta sortPtr
                ;lda #<(-1)
                ;sta sortRequired

                rts

    ;-------------------------------------------------------------------------------------

    DEF Resync
                RESYNC
Ret             rts

;------------------------------------------------------------------------------


OverscanTime
    .byte OVERSCAN_TIM_NTSC, OVERSCAN_TIM_NTSC
    .byte OVERSCAN_TIM_PAL, OVERSCAN_TIM_NTSC


THROT_BASE = 18
theThrottler
        .byte THROT_BASE, THROT_BASE, THROT_BASE*60/50, THROT_BASE

    DEF PostScreenCleanup

                iny                             ; --> 0

                sty COLUBK                      ; starts colour change bottom score area, wraps to top score area
                                                ; + moved here so we don't see a minor colour artefact bottom of screen when look-arounding

                sty PF0                         ; why wasn't this here?  I saw colour glitching in score area!
                                                ; TJ: no idea why, but you had removed it in revision 758 ;)
                                                ; completely accidental -- one of our cats may have deleted it.
                sty PF1
                sty PF2
                sty ENAM0
                sty GRP0                        ; when look-scrolling, we can see feet at the top if these aren't here
                sty GRP1                        ; 30/12/2011 -- fix dots @ top!

    ; D1 VBLANK turns off beam

                lda #%01000010                  ; bit6 is not required
                sta VBLANK                      ; end of screen - enter blanking

    ;------------------------------------------------------------------------------
    ; This is where the PAL system has a bit of extra time on a per-frame basis.

                ldx Platform
                lda OverscanTime,x
                sta TIM64T


    ;----------------------------------------------------------------------------------------------

    ; has to be done AFTER screen display, because it disables the effect!
                ;SLEEP 6
                ;lda rnd                     ; 3     randomly reposition the Cosmic Ark missile
                ;sta HMM0                    ; 3     this assumes that HMOVE is called at least once/frame

noFlashBG
;       sta BGColour

    ; Create a 'standardised' joystick with D4-D7 having bits CLEAR if the appropriate direction is chosen.

;                lda SWCHA
;                and BufferedJoystick
;                sta BufferedJoystick

                rts

;---------------------------------------------------------------------------------------------------

    DEF StartClearBoard

                ldx #8
                stx drawCount               ; = bank
                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF ClearEachRow

                dec drawCount
                bmi .bitmapCleared
                ldy drawCount
                jmp CallClear

.bitmapCleared

                lda #63
                sta drawPieceNumber

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------


    DEF FB3
                lda #BLANK
                sta previousPiece

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF EraseStartPiece


                lda toSquare
                cmp fromSquare
                beq .idleErase

                lda #6                  ; on/off count
                sta drawCount           ; flashing for piece about to move
                lda #0
                sta drawDelay

                inc drawPhase
.idleErase      rts

;---------------------------------------------------------------------------------------------------

    DEF WriteStartPieceBlank


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
                sta drawDelay               ; "getting ready to move" flash

                lda fromSquare
                sta drawPieceNumber
                jsr SAFE_CopySinglePiece         ; EOR-draw = flash
                rts

flashDone       inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------


    DEF DEB2

                jsr SAFE_CopySinglePiece
                dec drawPieceNumber
                bmi .comp

                dec drawPhase
                rts

.comp           inc drawPhase
                rts


;---------------------------------------------------------------------------------------------------

    DEF MarchB

    ; Draw the piece in the new square

                lda fromSquare
                sta drawPieceNumber
                jsr SAFE_CopySinglePiece             ; draw the moving piece into the new square

                lda #6                          ; snail trail delay
                sta drawDelay

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF FinalFlash

                lda drawDelay
                beq .deCount
                dec drawDelay
                rts

.deCount        lda drawCount
                beq flashDone2
                dec drawCount

                lda #10
                sta drawDelay               ; "getting ready to move" flash

                lda fromSquare
                sta drawPieceNumber
                jsr SAFE_CopySinglePiece
                rts


flashDone2      inc drawPhase
                rts


;---------------------------------------------------------------------------------------------------

    DEF CastleFixup

    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king


                lda fromPiece
                and #FLAG_CASTLE
                beq .noCast

                ldx #4
                lda toSquare
.findCast       dex
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

                lda #CSL
                sta drawPhase
                rts


.noCast
                lda sideToMove
                eor #128
                sta sideToMove
                bmi .skip
                lda #0
                sta aiPhase
.skip
                rts


KSquare         .byte 2,6,58,62
RSquareStart    .byte 22,29,92,99
RSquareEnd      .byte 25,27,95,97
RSquareStart64  .byte 0,7,56,63
RSquareEnd64    .byte 3,5,59,61



;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    ; SAFE

                ldy #7
.copyRowBanks   ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                jsr SAFE_CopyShadowROMtoRAM
                dey
                bpl .copyRowBanks

    ; copy the BOARD/MOVES bank

                ldy #RAMBANK_MOVES_RAM
                ldx #MOVES
                jsr SAFE_CopyShadowROMtoRAM              ; this auto-initialises Board too

    ; copy the PLY banks

                lda #MAX_PLY
                sta __plyBank
                ldy #RAMBANK_PLY
                sty currentPly
.copyPlyBanks   ldx #BANK_PLY
                jsr SAFE_CopyShadowROMtoRAM
                iny
                dec __plyBank
                bne .copyPlyBanks

    ; The state machine bank

;                ldy #RAMBANK_STATEMACHINE
;                ldx #STATEMACHINE
;                jsr SAFE_CopyShadowROMtoRAM

                rts


;---------------------------------------------------------------------------------------------------


            CHECK_BANK_SIZE "GENERIC_BANK_1 -- full 2K"
