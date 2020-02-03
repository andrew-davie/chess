; Copyright (C)2020 Andrew Davie
; Knight move handler

;---------------------------------------------------------------------------------------------------
; KNIGHT
;---------------------------------------------------------------------------------------------------

    DEF Handle_KNIGHT

    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TO _DOWN+_DOWN+_LEFT
                MOVE_TO_X _DOWN+_DOWN+_RIGHT
                MOVE_TO_X _UP+_UP+_LEFT
                MOVE_TO_X _UP+_UP+_RIGHT

                MOVE_TO_X _DOWN+_LEFT+_LEFT
                MOVE_TO_X _DOWN+_RIGHT+_RIGHT
                MOVE_TO_X _UP+_LEFT+_LEFT
                MOVE_TO_X _UP+_RIGHT+_RIGHT

                jmp MoveReturn

; EOF
