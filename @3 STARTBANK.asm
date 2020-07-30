_ORIGIN             SET _FIRST_BANK

; This is the first (START UP) bank for the 3E+ cartridge/scheme
; This bank is guaranteed to be mapped to SLOT 3 by the hardware implementation.
; It must contain the reset vector for the game!
; It does NOT need to be switched in for the remainder of the game!

;---------------------------------------------------------------------------------------------------

    SLOT 3
    ROMBANK STARTBANK


;---------------------------------------------------------------------------------------------------

    DEF StartCartridge

                    CLEAN_START
                    JUMP StartupBankReset;@0

;---------------------------------------------------------------------------------------------------

    ; Lots of free space here

;---------------------------------------------------------------------------------------------------

    ECHO "FREE BYTES IN STARTBANK = ", $FFFC - *


;---------------------------------------------------------------------------------------------------

    ; The reset vectors
    ; these must live in the fixed bank (bank 0 in 3E+ format)

    ORG _FIRST_BANK + $3FC
    RORG $FFFC
    DEF InterruptVectors
    SUBROUTINE

                    .word StartCartridge            ; RESET
                    .word StartCartridge            ; IRQ        (not used)


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
;EOF
