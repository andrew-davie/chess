; Copyright (C)2020 Andrew Davie

;---------------------------------------------------------------------------------------------------
; BISHOP
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_BISHOP

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN+_LEFT
                MOVE_TOWARDS _DOWN+_RIGHT
                MOVE_TOWARDS _UP+_LEFT
                MOVE_TOWARDS _UP+_RIGHT
                rts


            ;CHECK_HALF_BANK_SIZE "HANDLER_MOVE -- 1K"
