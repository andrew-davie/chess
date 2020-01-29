; Copyright (C)2020 Andrew Davie
; Knight move handler

;---------------------------------------------------------------------------------------------------
; KNIGHT
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_KNIGHT
    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

    #if 1
                MOVE_TO _DOWN+_DOWN+_LEFT
                MOVE_TO _DOWN+_DOWN+_RIGHT
                MOVE_TO _UP+_UP+_LEFT
                MOVE_TO _UP+_UP+_RIGHT

                MOVE_TO _DOWN+_LEFT+_LEFT
                MOVE_TO _DOWN+_RIGHT+_RIGHT
                MOVE_TO _UP+_LEFT+_LEFT
                MOVE_TO _UP+_RIGHT+_RIGHT
    #endif

                jmp MoveReturn

; EOF
