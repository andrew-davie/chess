; Copyright (C)2020 Andrew Davie


;---------------------------------------------------------------------------------------------------

    SLOT 3
    RAMBANK BOARD               ; RAM bank for holding the following ROM shadow

ValidSquare = ShadowValidSquare + $400
Board = ShadowBoard + $400
RandomBoardSquare = ShadowRandomBoardSquare + $400


    END_BANK


;---------------------------------------------------------------------------------------------------

    SLOT 2
    ROMBANK SHADOW_BOARD           ; copy the following bank to RAMBANK_BOARD

; Board is a 10 x 12 object which simplifies the generation of moves
; The squares marked '░░░' are illegal. The ("X12") index of each square is the left
; number + the bottom number. Bottom left legal square (AS VISIBLE ON SCREEN) is #22

;     X12 numbering
;    ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
;110 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;100 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
; 90 ┃░░░┊░░░┊ 92┊ 93┊ 94┊ 95┊ 96┊ 97┊ 98┊ 99┃ 8 BLACK
; 80 ┃░░░┊░░░┊ 82┊ 83┊ 84┊ 85┊ 86┊ 87┊ 88┊ 89┃ 7 BLACK
; 70 ┃░░░┊░░░┊ 72┊ 73┊ 74┊ 75┊ 76┊ 77┊ 78┊ 79┃ 6
; 60 ┃░░░┊░░░┊ 62┊ 63┊ 64┊ 65┊ 66┊ 67┊ 68┊ 69┃ 5
; 50 ┃░░░┊░░░┊ 52┊ 53┊ 54┊ 55┊ 56┊ 57┊ 58┊ 59┃ 4
; 40 ┃░░░┊░░░┊ 42┊ 43┊ 44┊ 45┊ 46┊ 47┊ 48┊ 49┃ 3 
; 30 ┃░░░┊░░░┊ 32┊ 33┊ 34┊ 35┊ 36┊ 37┊ 38┊ 39┃ 2 WHITE
; 20 ┃░░░┊░░░┊ 22┊ 23┊ 24┊ 25┊ 26┊ 27┊ 28┊ 29┃ 1 WHITE
; 10 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;  0 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;    ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;      0   1   2   3   4   5   6   7   8   9
;              A   B   C   D   E   F   G   H

;     HEX X12
;    ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
;110 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;100 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
; 90 ┃░░░┊░░░┊$5C┊$5D┊$5E┊$5F┊$60┊$61┊$62┊$63┃ 8
; 80 ┃░░░┊░░░┊$52┊$53┊$54┊$55┊$56┊$57┊$58┊$59┃ 7
; 70 ┃░░░┊░░░┊$48┊$49┊$4A┊$4B┊$4C┊$4D┊$4E┊$4F┃ 6
; 60 ┃░░░┊░░░┊$3E┊$3F┊$40┊$41┊$42┊$43┊$44┊$45┃ 5
; 50 ┃░░░┊░░░┊$34┊$35┊$36┊$37┊$38┊$39┊$3A┊$3B┃ 4
; 40 ┃░░░┊░░░┊$2A┊$2B┊$2C┊$2D┊$2E┊$2F┊$30┊$31┃ 3
; 30 ┃░░░┊░░░┊$20┊$21┊$22┊$23┊$24┊$25┊$26|$27┃ 2
; 20 ┃░░░┊░░░┊$16┊$17┊$18┊$19┊$1A┊$1B┊$1C┊$1D┃ 1
; 10 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;  0 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;    ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;      0   1   2   3   4   5   6   7   8   9
;              A   B   C   D   E   F   G   H

    DEF ShadowRandomBoardSquare
        ds 64


    ; We put a short buffer before 'ValidSquare' when it is at the start of the bank, so that
    ; the move indexing (ie., "ValidSquare+{1},x" won't drop off the beginning of the bank
    ; and cause "segfaults". 21 is the max offset (a knight move). These spare bytes can
    ; be re-used for something else - we just need to guarantee there are 21 of them there

    ALLOCATE Valid, 120 + 80  ;+ 21
    ;ds 21                      ; so indexing of "ValidSquare-21,x" won't fail

    ; 20200910 21 not required as long as there's something defined earlier that's big enough
    ; in this case, RandomBoardSquare


    ; Note, we will never index INTO the above bytes - x will always be >= 21
    ; We just need to make sure that the actual indexing will not have an address before
    ; the index of outside the page.

    DEF ShadowValidSquare


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

    DEF ShadowBoard

    ; A 10X10... we should never write using invalid square
    ; ON COPY TO RAM BANK, 'BOARD' SELF-INITIALISES TO THE FOLLOWING VALUES
    ; FROM THEN ON IT'S WRITEABLE (REMEMBER TO +RAM_WRITE) FOR MODIFICATIONS

    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table
    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table

    REPEAT 8
        .byte -1, -1, 0, 0, 0, 0, 0, 0, 0, 0
    REPEND

SIZEOF_ShadowBoard = * - ShadowBoard

    ; DON'T OVERSTEP BOUNDS WHEN WRITING BOARD - MAXIMUM INDEX = 99


;---------------------------------------------------------------------------------------------------
; EOF
