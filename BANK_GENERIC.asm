
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

        REFER Reset
        VEND Cart_Init

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

#if 0
    DEF Resync
    SUBROUTINE

                    RESYNC
                    rts
#endif

;---------------------------------------------------------------------------------------------------

    DEF aiStartClearBoard
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStartClearBoard

                    ldx #8
                    stx drawCount                   ; = bank

                    lda #-1
                    sta cursorX12

                    PHASE AI_ClearEachRow
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiClearEachRow
    SUBROUTINE

        REFER AiStateMachine
        VEND aiClearEachRow

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

        REFER AiStateMachine
        VEND aiMoveIsSelected


    ; Both computer and human have now seleted a move, and converge here


    ; fromPiece     piece doing the move
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

        REFER AiStateMachine
        VEND aiWriteStartPieceBlank

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

        REFER AiStateMachine
        VEND aiDrawPart2

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

        REFER AiStateMachine
        VEND aiMarchB

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

        REFER AiStateMachine
        VEND aiFinalFlash


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
