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

                ldx currentSquare
                lda Board+{1},x             ; kingside/queenside R position
                and #PIECE_MASK|FLAG_MOVED
                cmp #ROOK
                bne .noCastle               ; not a R that hasn't moved

        ; It's a R and it *HAS* to be correct colour because it hasn't moved!
        ; AND the K hasn't moved (earlier check), so check for vacant squares between K and R

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

        ; appropriate N/B/(Q) squares are vacant so we proceed...

    ; FINALLY -- king can castle
    ; note: when we actually DO the move we MUST insert "Phantom" kings onto the board over the
    ; squares the king traverses so that "check" (and thus illegal moves) can be detected on the
    ; next move. Castling will be detected by K moving > 1 square. (TODO: FIX?? not CASTLE flag??)

                lda currentPiece
                ora #FLAG_CASTLE                   ; flag it's a castling move
                sta currentPiece

                ldy ValidSquare+{2},x

                jsr AddMove

.noCastle
    ENDM


;---------------------------------------------------------------------------------------------------

    DEF Handle_KING

    ; x = currentSquare (square the KING is on)
    ; currentPiece (KING of course, but with flags/colour attached)

                MOVE_TO _DOWN+_LEFT
                MOVE_TO_X _DOWN
                MOVE_TO_X _DOWN+_RIGHT
                MOVE_TO_X _RIGHT
                MOVE_TO_X _UP+_RIGHT
                MOVE_TO_X _UP
                MOVE_TO_X _UP+_LEFT
                MOVE_TO_X _LEFT

                bit currentPiece
                bvs .retMov                 ; king has moved, so no castling

                CASTLE KINGSIDE, 2
                CASTLE QUEENSIDE, -2

.retMov         jmp MoveReturn

;---------------------------------------------------------------------------------------------------
; EOF
