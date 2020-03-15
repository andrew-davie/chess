; Copyright (C)2020 Andrew Davie

;---------------------------------------------------------------------------------------------------

    NEWRAMBANK MOVES_RAM                ; RAM bank for holding the following ROM shadow
    NEWBANK MOVES                       ; copy the following bank to RAMBANK_MOVES_RAM

; Board is a 10 x 12 object which simplifies the generation of moves
; The squares marked '░░░' are illegal. The ("X12") index of each square is the left
; number + the bottom number. The "BASE64" square numbering is used to simplify movement code.
; Bottom left legal square (AS VISIBLE ON SCREEN) is #22

;     X12 numbering
;    ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
;110 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃             BASE64 numbering
;100 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃             ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
; 90 ┃░░░┊░░░┊ 92┊ 93┊ 94┊ 95┊ 96┊ 97┊ 98┊ 99┃  BLACK    8 ┃ 56┊ 57┊ 58┊ 59┊ 60┊ 61┊ 62┊ 63┃
; 80 ┃░░░┊░░░┊ 82┊ 83┊ 84┊ 85┊ 86┊ 87┊ 88┊ 89┃  BLACK    7 ┃ 48┊ 49┊ 50┊ 51┊ 52┊ 53┊ 54┊ 55┃
; 70 ┃░░░┊░░░┊ 72┊ 73┊ 74┊ 75┊ 76┊ 77┊ 78┊ 79┃           6 ┃ 40┊ 41┊ 42┊ 43┊ 44┊ 45┊ 46┊ 47┃
; 60 ┃░░░┊░░░┊ 62┊ 63┊ 64┊ 65┊ 66┊ 67┊ 68┊ 69┃           5 ┃ 32┊ 33┊ 34┊ 35┊ 36┊ 37┊ 38┊ 39┃
; 50 ┃░░░┊░░░┊ 52┊ 53┊ 54┊ 55┊ 56┊ 57┊ 58┊ 59┃           4 ┃ 24┊ 25┊ 26┊ 27┊ 28┊ 29┊ 30┊ 31┃
; 40 ┃░░░┊░░░┊ 42┊ 43┊ 44┊ 45┊ 46┊ 47┊ 48┊ 49┃           3 ┃ 16┊ 17┊ 18┊ 19┊ 20┊ 21┊ 22┊ 23┃
; 30 ┃░░░┊░░░┊ 32┊ 33┊ 34┊ 35┊ 36┊ 37┊ 38┊ 39┃  WHITE    2 ┃  8┊  9┊ 10┊ 11┊ 12┊ 13┊ 14┊ 15┃
; 20 ┃░░░┊░░░┊ 22┊ 23┊ 24┊ 25┊ 26┊ 27┊ 28┊ 29┃  WHITE    1 ┃  0┊  1┊  2┊  3┊  4┊  5┊  6┊  7┃
; 10 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃             ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;  0 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃               A   B   C   D   E   F   G   H
;    ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;      0   1   2   3   4   5   6   7   8   9
;              A   B   C   D   E   F   G   H

;     HEX X12
;    ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
;110 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;100 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
; 90 ┃░░░┊░░░┊$5C┊$5D┊$5E┊$5F┊$60┊$61┊$62┊$63┃
; 80 ┃░░░┊░░░┊$52┊$53┊$54┊$55┊$56┊$57┊$58┊$59┃
; 70 ┃░░░┊░░░┊$48┊$49┊$4A┊$4B┊$4C┊$4D┊$4E┊$4F┃
; 60 ┃░░░┊░░░┊$3E┊$3F┊$40┊$41┊$42┊$43┊$44┊$45┃
; 50 ┃░░░┊░░░┊$34┊$35┊$36┊$37┊$38┊$39┊$3A┊$3B┃
; 40 ┃░░░┊░░░┊$2A┊$2B┊$2C┊$2D┊$2E┊$2F┊$30┊$31┃
; 30 ┃░░░┊░░░┊$20┊$21┊$22┊$23┊$24┊$25┊$26|$27┃
; 20 ┃░░░┊░░░┊$16┊$17┊$18┊$19┊$1A┊$1B┊$1C┊$1D┃
; 10 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;  0 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;    ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;      0   1   2   3   4   5   6   7   8   9
;              A   B   C   D   E   F   G   H


    ; We put a short buffer before 'ValidSquare' when it is at the start of the bank, so that
    ; the move indexing (ie., "ValidSquare+{1},x" won't drop off the beginning of the bank
    ; and sause "segfaults". 22 is the max offset (a knight move). These spare bytes can
    ; be re-used for something else - we just need to guarantee there are 21 of them there

    ALLOCATE Valid, 120 + 80 + 21
    ds 21                      ; so indexing of "ValidSquare-21,x" won't fail

    ; Note, we will never index INTO the above bytes - x will always be >= 22
    ; We just need to make sure that the actual indexing will not have an address before
    ; the index of outside the page.

    DEF ValidSquare


    ; Use this table to
    ;   a) Determine if a square is valid (-1 = NO)
    ;   b) Move pieces without addition.  e.g., "lda ValidSquareTable+10,x" will let you know
    ;      if a white pawn on square "x" can move "up" the board.

    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    .byte -1, -1, 22, 23, 24, 25, 26, 27, 28, 29
    .byte -1, -1, 32, 33, 34, 35, 36, 37, 38, 39
    .byte -1, -1, 42, 43, 44, 45, 46, 47, 48, 49
    .byte -1, -1, 52, 53, 54, 55, 56, 57, 58, 59
    .byte -1, -1, 62, 63, 64, 65, 66, 67, 68, 69
    .byte -1, -1, 72, 73, 74, 75, 76, 77, 78, 79
    .byte -1, -1, 82, 83, 84, 85, 86, 87, 88, 89
    .byte -1, -1, 92, 93, 94, 95, 96, 97, 98, 99    ; CONTINUES...

    DEF Board

    ; A 10X10... we should never write using invalid square
    ; ON COPY TO RAM BANK, 'BOARD' SELF-INITIALISES TO THE FOLLOWING VALUES
    ; FROM THEN ON IT'S WRITEABLE (REMEMBER TO +RAM_WRITE) FOR MODIFICATIONS

    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table
    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table

    REPEAT 8
        .byte -1, -1, 0, 0, 0, 0, 0, 0, 0, 0
    REPEND

    ; DON'T OVERSTEP BOUNDS WHEN WRITING BOARD - MAXIMUM INDEX = 99

    ; PARANOIA... following not used, but there in case above violated
    ;.byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table
    ;.byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table

;---------------------------------------------------------------------------------------------------

    include "Handler_QUEEN.asm"
    include "Handler_BISHOP.asm"
    include "Handler_ROOK.asm"
    include "Handler_KING.asm"
    include "Handler_KNIGHT.asm"


;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "HANDLER_BANK1 -- 1K"


; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!


 include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_0.asm"
 include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_1.asm"
 include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_2.asm"
 include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_3.asm"
 include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_0.asm"
 include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_1.asm"
 include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_2.asm"
 include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_3.asm"

;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "HANDLER_BANK_1 -- full 2K"

;---------------------------------------------------------------------------------------------------
; EOF
