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

                ldx currentSquare
                lda Board+{1},x             ; we expect a R
                sta __piece

                and #PIECE_MASK
                cmp #ROOK
                bne .noCastle               ; not a R

                lda __piece
                eor currentPiece
                bmi .noCastle               ; not correct colour

                bit __piece
                bvs .noCastle               ; it's previously moved so we can't castle

        ; Check for vacant squares between K and R

        IF {1} = QUEENSIDE
                lda Board-3,x               ; nothing in N pos
                bne .noCastle
                lda Board-2,x               ; nothing in B pos
                bne .noCastle
                lda Board-1,x               ; nothing in Q pos
                bne .noCastle

        ENDIF

        IF {1} = KINGSIDE
                lda Board+2,x               ; check N pos
                bne .noCastle
                lda Board+1,x               ; check B pos
                bne .noCastle
        ENDIF

        ; appropriate N/B/(Q) squares are vacant so we proceed with more checks...

    ; FINALLY -- king can castle
    ; note: when we actually DO the move we MUST insert "Phantom" kings onto the board over the
    ; squares the king traverses so that "check" (and thus illegal moves) can be detected on the
    ; next move. Castling will be detected by K moving > 1 square.

                lda currentPiece
                ora #CASTLE
                sta currentPiece

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

                MOVE_TO _DOWN+_LEFT
                MOVE_TO_X _DOWN
                MOVE_TO_X _DOWN+_RIGHT
                MOVE_TO_X _RIGHT
                MOVE_TO_X _UP+_RIGHT
                MOVE_TO_X _UP
                MOVE_TO_X _UP+_LEFT
                MOVE_TO_X _LEFT

                bit currentPiece            ; has king moved moved?
                bvc .castleKing             ; no, so try castling

                jmp MoveReturn

.castleKing     CASTLE KINGSIDE, 2
                CASTLE QUEENSIDE, -2

                jmp MoveReturn

;---------------------------------------------------------------------------------------------------
; EOF
