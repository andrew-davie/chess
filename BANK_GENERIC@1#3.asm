    SLOT 1
            NEWBANK GENERIC_BANK_2

;---------------------------------------------------------------------------------------------------

    DEF aiWriteStartPieceBlank
    SUBROUTINE

        REFER AiStateMachine
        VEND aiWriteStartPieceBlank

    ; Flash the piece in-place preparatory to moving it.
    ; drawDelay = flash speed
    ; drawCount = # of flashes

                    lda originX12
                    sta cursorX12

                    lda #%100
                    sta CTRLPF
                    lda #2
                    sta COLUP0


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

                    jsr CopySinglePiece;@0          ; EOR-draw = flash
                    rts

flashDone

                    PHASE AI_MarchToTargetA
                    rts


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
                    beq .flashDone2
                    dec drawCount

                    lda #10
                    sta drawDelay               ; "getting ready to move" flash

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0
                    rts

.flashDone2

                    lda #100
                    sta aiFlashDelay

                    PHASE AI_SpecialMoveFixup
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
