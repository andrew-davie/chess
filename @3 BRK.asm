_ORIGIN             SET _FIRST_BANK

; This is the first (START UP) bank for the 3E+ cartridge/scheme
; This bank is guaranteed to be mapped to SLOT 3 by the hardware implementation.
; It must contain the reset vector for the game!
; It does NOT need to be switched in for the remainder of the game!

;---------------------------------------------------------------------------------------------------

    SLOT 3
    ROMBANK BRKBANK


;---------------------------------------------------------------------------------------------------

    DEF DoBreak

                    brk


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
;EOF
