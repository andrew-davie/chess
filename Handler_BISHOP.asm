; Copyright (C)2020 Andrew Davie

;---------------------------------------------------------------------------------------------------
; BISHOP
;---------------------------------------------------------------------------------------------------

    DEF Handle_BISHOP

    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN+_LEFT
                MOVE_TOWARDS _DOWN+_RIGHT
                MOVE_TOWARDS _UP+_LEFT
                MOVE_TOWARDS _UP+_RIGHT

                jmp MoveReturn

;---------------------------------------------------------------------------------------------------
; EOF
