; Copyright (C)2020 Andrew Davie

; This is the move handler for a KING
; "Check" is detected in the next ply of the search, so the move generation doesn't have to
; be concerned about that. To assist with castling over squares in check (which is illegal)
; the concept of a phantom king is introduced. Phantom kings are effectively blank squares
; but need to be checked when moving opposite-colour pieces to a square. Messy.

    NEWRAMBANK HANDLER_KING
    ; Handles everything to do with king moving

    include "common_vectors.asm"         ; MUST BE FIRST

;---------------------------------------------------------------------------------------------------
; MACRO - Common code
; Looks at a square offset {1} to see if piece can move to it
; Adds the square to the movelist if it can

    MAC MOVE_TO
    SUBROUTINE

                ldy ValidSquare+{1},x
                bmi .invalid                    ; off board!
                lda Board,y                     ; piece @ destination
                beq .squareEmpty

                eor currentPiece
                bpl .invalid                    ; same colour

.squareEmpty    jsr AddMove
.invalid
    ENDM

;---------------------------------------------------------------------------------------------------
; MACRO - Castling

KINGSIDE        = 3
QUEENSIDE       = -4

    MAC CASTLE
    ; {1} == KINGSIDE or QUEENSIDE
    SUBROUTINE

        ; Most likely failure trigger is there are pieces in the way (N or B) (or Q)
        ; Check these squares first as it's the cheapest "exit" from castle check

        ; Note: castling with squares that are "in check" is problematic
        ; TODO: next ply have a "phantom" king on the positions king moves over...?

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
                MOVE_TO _DOWN
                MOVE_TO _DOWN+_RIGHT
                MOVE_TO _RIGHT
                MOVE_TO _UP+_RIGHT
                MOVE_TO _UP
                MOVE_TO _UP+_LEFT
                MOVE_TO _LEFT

    ; castling...

                bit currentPiece            ; WARNING: D6 (=MOVED) assumed
                bvs .noCastle               ; can't castle - king has moved

                CASTLE KINGSIDE
                CASTLE QUEENSIDE

.noCastle
                rts


            CHECK_HALF_BANK_SIZE "HANDLER_KING -- 1K"
