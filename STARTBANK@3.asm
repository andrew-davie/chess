_ORIGIN             SET _FIRST_BANK

;---------------------------------------------------------------------------------------------------

    SLOT 3
    ROMBANK STARTBANK


;---------------------------------------------------------------------------------------------------

    DEF StartCartridge

                    CLEAN_START

                    lda #BANK_StartupBankReset
                    sta SET_BANK
                    jmp StartupBankReset


;---------------------------------------------------------------------------------------------------

    ECHO "FREE BYTES IN STARTBANK = ", $F3FB - *


;---------------------------------------------------------------------------------------------------

    ; The reset vectors
    ; these must live in the fixed bank (bank 0 in 3E+ format)


                SEG InterruptVectors
                ORG _FIRST_BANK + $3FC

                    .word StartCartridge            ; RESET
                    .word StartCartridge            ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
;EOF
