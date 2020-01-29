; Copyright (C)2020 Andrew Davie
; Piece move handler for king


; This is the move handler for a KING
; "Check" is detected in the next ply of the search, so the move generation doesn't have to
; be concerned about that. To assist with castling over squares in check (which is illegal)
; the concept of a phantom king is introduced. Phantom kings are effectively blank squares
; but need to be checked when moving opposite-colour pieces to a square. Messy.

;---------------------------------------------------------------------------------------------------
; MACRO - Castling

KINGSIDE        = 3
QUEENSIDE       = -4

    MAC CASTLE
    ; {1} == KINGSIDE or QUEENSIDE


        ; Most likely failure trigger is there are pieces in the way (N or B) (or Q)
        ; Check these squares first as it's the cheapest "exit" from castle check

        ; Note: castling with squares that are "in check" is problematic
        ; TODO: next ply have a "phantom" king on the positions king moves over...?

    ; todo: incomplete... x/y regs usage etc

                ldy currentSquare

        IF {1} = QUEENSIDE
                lda Board-3,y               ; nothing in N pos
                bne .noCastle
                lda Board-2,y               ; nothing in B pos
                bne .noCastle
                lda Board-1,y               ; nothing in Q pos
                bne .noCastle
        ENDIF

        IF {1} = KINGSIDE
                lda Board+2,y               ; check N pos
                bne .noCastle
                lda Board+1,y               ; check B pos
                bne .noCastle
        ENDIF

        ; appropriate N/B/(Q) squares are vacant so we proceed with more checks...

                lda Board+{1},y             ; we expect a R
                sta __piece

                and #PIECE_MASK
                cmp #ROOK
                bne .noCastle               ; not a R

                lda __piece
                eor currentPiece
                bmi .noCastle               ; not correct colour

                bit __piece
                bvs .noCastle               ; it's previously moved so we can't castle

    ; FINALLY -- king can castle
    ; note: when we actually DO the move we MUST insert "Phantom" kings onto the board over the
    ; squares the king traverses so that "check" (and thus illegal moves) can be detected on the
    ; next move. Castling will be detected by K moving > 1 square.

                lda currentPiece
                ora #CASTLE
                sta currentPiece

                ldx currentSquare
                ldy ValidSquare+{2},x

                jsr AddMove
.noCastle
    ENDM


;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_KING

    ; Pass...
    ; x = currentSquare (square the KING is on)
    ; currentPiece (KING of course, but with flags/colour attached)

    ; regular moving...

#if 1
                MOVE_TO _DOWN+_LEFT
                MOVE_TO _DOWN
                MOVE_TO _DOWN+_RIGHT
                MOVE_TO _RIGHT
                MOVE_TO _UP+_RIGHT
                MOVE_TO _UP
                MOVE_TO _UP+_LEFT
                MOVE_TO _LEFT
#endif

    ; castling...

                bit currentPiece            ; WARNING: D6 (=MOVED) assumed
                bvs .noCastle               ; can't castle - king has moved

                CASTLE KINGSIDE, 2
                CASTLE QUEENSIDE, -2

.noCastle

                jmp MoveReturn

;---------------------------------------------------------------------------------------------------
; EOF
