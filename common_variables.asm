            NEWRAMBANK COMMON_VARIABLES

Board           ds 144

    DEFINE_SUBROUTINE Init_Board

; Board is a 12 x 12 object which simplifies the generation of moves
; The squares marked 'X' are illegal. The index of each square is the left
; number + the bottom number. So, bottom left legal square is #26

; --> see ValidSquareTable for lookup

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




            CHECK_HALF_BANK_SIZE "COMMON_VARIABLES"
