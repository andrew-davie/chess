    SLOT 1
            NEWBANK GENERIC_BANK_2


;---------------------------------------------------------------------------------------------------

    DEF aiDrawPart2
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawPart2

                    jsr CopySinglePiece;@0

    DEF aiDrawPart3
    SUBROUTINE

                    dec squareToDraw
                    lda squareToDraw
                    cmp #22
                    bcc .comp

                    PHASE AI_DrawEntireBoard
                    rts

.comp

                    lda #-1
                    sta toX12                        ; becomes startup flash square
                    lda #36                         ; becomes cursor position
                    sta originX12


                    PHASE AI_GenerateMoves
                    rts
                    



;---------------------------------------------------------------------------------------------------

    DEF aiMarchB
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchB

    ; Draw the piece in the new square

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0          ; draw the moving piece into the new square

                    lda #10                          ; snail trail delay ??
                    sta drawDelay

                    PHASE AI_MarchToTargetB
                    rts



;---------------------------------------------------------------------------------------------------

    DEF aiDraw
    SUBROUTINE
                    lda #$C0
                    sta COLUBK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiCheckMate
    SUBROUTINE
                    lda #$44
                    sta COLUBK
                    rts

;---------------------------------------------------------------------------------------------------

            CHECK_BANK_SIZE "BANK_GENERIC2"

;---------------------------------------------------------------------------------------------------
;EOF
