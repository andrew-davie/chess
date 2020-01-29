; Copyright (C)2020 Andrew Davie
; Rook move handler

;---------------------------------------------------------------------------------------------------
; ROOK
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_ROOK

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

#if 1
                MOVE_TOWARDS _DOWN
                MOVE_TOWARDS _RIGHT
                MOVE_TOWARDS _UP
                MOVE_TOWARDS _LEFT
#endif

                jmp MoveReturn

;---------------------------------------------------------------------------------------------------
; EOF
