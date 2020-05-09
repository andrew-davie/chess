    SLOT 1
    NEWBANK RECON


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
