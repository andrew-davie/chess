; Copyright (C)2020 Andrew Davie

;---------------------------------------------------------------------------------------------------
; QUEEN
;---------------------------------------------------------------------------------------------------

    DEF Handle_QUEEN
    SUBROUTINE

        REF GenerateAllMoves ;✅
        VEND Handle_QUEEN

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN+_LEFT
                MOVE_TOWARDS _DOWN
                MOVE_TOWARDS _DOWN+_RIGHT
                MOVE_TOWARDS _RIGHT
                MOVE_TOWARDS _UP+_RIGHT
                MOVE_TOWARDS _UP
                MOVE_TOWARDS _UP+_LEFT
                MOVE_TOWARDS _LEFT

                jmp MoveReturn

; EOF
