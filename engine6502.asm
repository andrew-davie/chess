; 6502 chess engine
; Andrew Davie - January 2020

    NEWRAMBANK ENGINE6502





#if 0



    DEFINE_SUBROUTINE GenMoveForPiece

            ; a = piece
            ; x = square

                asl
                tay
                lda Move_Vector,y
                sta _vec
                lda Move_Vector+1,y
                sta _vec+1
                jmp (vec)


Move_Blank      rts

Move_White_Pawn

                ldy Square+12,x
                lda Board,y
                bne CaptureLeft
                jsr AddMove

                cpx #48             ; ~ (i.e., pawn must have originally been on start rank)
                bcs notOnStart

                ldy Square+24,x
                lda Board,y
                bne CaptureLeft
                jsr AddMove

notOnStart
CaptureLeft

                dey
                lda Board,y
                and #BLACK
                bne CaptureRight        ; ALSO CATCHES ILLEGALS
                jsr AddMove

CaptureRight
                iny
                iny
                lda Board,y
                and #BLACK
                bne enPassant           ; ALSO CATCHES ILLEGALS
                jsr AddMove


enPassant       rts




Move_Bishop     txa
                tay

AddMoveBish     jsr AddMove

BishAddMove1    lda Square+13,y
                tay
                lda Board,y
                beq AddMoveBish
                eor Board,x
                and #BLACK
                bne AddMoveBish
                jsr AddMove






Move_Vector

    .word Move_Blank            ; BLANK
    .word Move_White_Pawn
    .word Move_Knight
    .word Move_Bishop
    .word Move_Rook
    .word Move_Queen
    .word Move_King
    .word 0

    .word 0
    .word Move_Black_Pawn
    .word Move_Knight
    .word Move_Bishop
    .word Move_Rook
    .word Move_Queen
    .word Move_King
    .word 0






    DEFINE_SUBROUTINE Init_Board

; Board is a 12 x 12 object which simplifies the generation of moves
; The squares marked 'X' are illegal. The index of each square is the left
; number + the bottom number. So, bottom left legal square is #26

;    +---+---+---+---+---+---+---+---+---+---+---+---+
;132 | X | X | X | X | X | X | X | X | X | X | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
;120 | X | X | X | X | X | X | X | X | X | X | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
;108 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 96 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 84 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 72 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 60 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 48 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 36 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 24 | X | X |   |   |   |   |   |   |   |   | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
; 12 | X | X | X | X | X | X | X | X | X | X | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
;  0 | X | X | X | X | X | X | X | X | X | X | X | X |
;    +---+---+---+---+---+---+---+---+---+---+---+---+
;      0   1   2   3   4   5   6   7   8   9   10  11

                ldx #144
                lda #-1
.fill_illegal   sta Board-1,x
                dex
                bpl .fill_illegal

                rts

#endif


            CHECK_BANK_SIZE "ENGINE6502 -- full 2K"
