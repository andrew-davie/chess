    SLOT 1
    NEWBANK RECON

;---------------------------------------------------------------------------------------------------

    DEF SAFE_showMoveCaptures
    SUBROUTINE

        VEND SAFE_showMoveCaptures

                    jsr UNSAFE_showMoveCaptures
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF UNSAFE_showMoveCaptures
    SUBROUTINE

        REFER SAFE_showMoveCaptures
        VAR __toSquareX12, 1
        VAR __fromPiece, 1
        VAR __aiMoveIndex, 1
        VEND UNSAFE_showMoveCaptures

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked

                    lda savedBank
                    pha

                    lda #BANK_UNSAFE_showMoveCaptures
                    sta savedBank


.next               ldx aiMoveIndex
                    stx __aiMoveIndex
                    bmi .skip                       ; no moves in list

                    lda INTIM
                    cmp #20
                    bcc .skip

                    dec aiMoveIndex

                    jsr GetP_MoveFrom
                    cmp fromX12
                    bne .next


                    jsr GetP_MoveTo
                    sta __toSquareX12
                    tay
                    jsr GetBoard
                    and #PIECE_MASK
                    beq .next

    ; There's something on the board at destination, so it's a capture
    ; Let's see if we are doing a pawn promote...

                    ldy fromX12
                    jsr GetBoard
                    sta __fromPiece

                    jsr GetP_MovePiece
                    eor __fromPiece
                    and #PIECE_MASK
                    beq .legit                  ; from == to, so not a promote

    ; Have detected a promotion duplicate - skip all 3 of them

                    dec aiMoveIndex                 ; skip "KBRQ" promotes
                    dec aiMoveIndex
                    dec aiMoveIndex

.legit

        ;TIMECHECK COPYSINGLEPIECE, restoreIndex     ; not enough time to draw

                    lda __toSquareX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0

.skip               pla
                    sta savedBank
                    rts


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REFER aiRollPromotionPiece
        REFER aiChoosePromotePiece
        VEND showPromoteOptions

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    jsr CopySetupForMarker
                    jmp InterceptMarkerCopy



;---------------------------------------------------------------------------------------------------


    CHECK_BANK_SIZE "BANK_RECON"

; EOF
