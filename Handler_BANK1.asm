; Copyright (C)2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------

    NEWRAMBANK MOVES_RAM                ; RAM bank for holding the following ROM shadow
    NEWBANK MOVES                       ; copy the following bank to RAMBANK_MOVES_RAM


; Board is a 12 x 10 object which simplifies the generation of moves
; The squares marked '░░░' are illegal. The index of each square is the left
; number + the bottom number. Screen is flipped vertically compared to memory layout.
; So, bottom left legal square (AS VISIBLE ON SCREEN) is #22

;    ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
;  0 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃          BASE64 numbering
; 10 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃         ┏━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┯━━━┓
; 20 ┃░░░┊░░░┊ 22┊ 23┊ 24┊ 25┊ 26┊ 27┊ 28┊ 29┃ <-- W   ┃  0┊  1┊  2┊  3┊  4┊  5┊  6┊  7┃
; 30 ┃░░░┊░░░┊ 32┊ 33┊ 34┊ 35┊ 36┊ 37┊ 38┊ 39┃ <-- W   ┃  8┊  9┊ 10┊ 11┊ 12┊ 13┊ 14┊ 15┃
; 40 ┃░░░┊░░░┊ 42┊ 43┊ 44┊ 45┊ 46┊ 47┊ 48┊ 49┃         ┃ 16┊ 17┊ 18┊ 19┊ 20┊ 21┊ 22┊ 23┃
; 50 ┃░░░┊░░░┊ 52┊ 53┊ 54┊ 55┊ 56┊ 57┊ 58┊ 59┃         ┃ 24┊ 25┊ 26┊ 27┊ 28┊ 29┊ 30┊ 31┃
; 60 ┃░░░┊░░░┊ 62┊ 63┊ 64┊ 65┊ 66┊ 67┊ 68┊ 69┃         ┃ 32┊ 33┊ 34┊ 35┊ 36┊ 37┊ 38┊ 39┃
; 70 ┃░░░┊░░░┊ 72┊ 73┊ 74┊ 75┊ 76┊ 77┊ 78┊ 79┃         ┃ 40┊ 41┊ 42┊ 43┊ 44┊ 45┊ 46┊ 47┃
; 80 ┃░░░┊░░░┊ 82┊ 83┊ 84┊ 85┊ 86┊ 87┊ 88┊ 89┃ <-- B   ┃ 48┊ 49┊ 50┊ 51┊ 52┊ 53┊ 54┊ 55┃
; 90 ┃░░░┊░░░┊ 92┊ 93┊ 94┊ 95┊ 96┊ 97┊ 98┊ 99┃ <-- B   ┃ 56┊ 57┊ 58┊ 59┊ 60┊ 61┊ 62┊ 63┃
;100 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃         ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;110 ┃░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┊░░░┃
;    ┗━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┷━━━┛
;      0   1   2   3   4   5   6   7   8   9


WHITE_PAWN_HOME_ROW     = 40                    ; < this, on home row
BLACK_PAWN_HOME_ROW     = 82                    ; >= this, on home row


    OPTIONAL_PAGEBREAK "ValidSquare", 120 + 80
    DEFINE_SUBROUTINE ValidSquare

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

    DEFINE_SUBROUTINE Board
    DEFINE_SUBROUTINE Chessboard

    ; A 10X10...
    ; ON COPY TO RAM BANK, 'BOARD' SELF-INITIALISES TO THE FOLLOWING VALUES
    ; FROM THEN ON IT'S WRITEABLE (REMEMBER TO +RAM_WRITE) FOR MODIFICATIONS

    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table
    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1        ; shared with above table

    .byte -1, -1,  WHITE|R,  WHITE|N,  WHITE|B,  WHITE|Q,  WHITE|K,  WHITE|B,  WHITE|N,  WHITE|R
    .byte -1, -1, WHITE|WP, WHITE|WP, WHITE|WP, WHITE|WP, WHITE|WP, WHITE|WP, WHITE|WP, WHITE|WP
    .byte -1, -1,        0,        0,        0,        0,        0,        0,        0,        0
    .byte -1, -1,        0,        0,        0,        0,        0,        0,        0,        0
    .byte -1, -1,        0,        0,        0,        0,        0,        0,        0,        0
    .byte -1, -1,        0,        0,        0,        0,        0,        0,        0,        0
    .byte -1, -1, BLACK|BP, BLACK|BP, BLACK|BP, BLACK|BP, BLACK|BP, BLACK|BP, BLACK|BP, BLACK|BP
    .byte -1, -1,  BLACK|R,  BLACK|N,  BLACK|B,  BLACK|Q,  BLACK|K,  BLACK|B,  BLACK|N,  BLACK|R

    ; DON'T OVERSTEP BOUNDS WHEN WRITING BOARD - MAXIMUM INDEX = 103

;---------------------------------------------------------------------------------------------------

HandlerVectorLO

    .byte 0                     ; blank
    .byte <Handle_WHITE_PAWN
    .byte <Handle_BLACK_PAWN
    .byte <Handle_KNIGHT
    .byte <Handle_BISHOP
    .byte <Handle_ROOK
    .byte <Handle_QUEEN
    .byte <Handle_KING

HandlerVectorHI

    .byte 0                     ; blank
    .byte >Handle_WHITE_PAWN
    .byte >Handle_BLACK_PAWN
    .byte >Handle_KNIGHT
    .byte >Handle_BISHOP
    .byte >Handle_ROOK
    .byte >Handle_QUEEN
    .byte >Handle_KING

;---------------------------------------------------------------------------------------------------

Piece

    ; 16 bytes defining square on which a piece is

    .byte 26,27,28,29,30,31,32,33
    .byte 38,39,40,41,42,43,44,45

;---------------------------------------------------------------------------------------------------

; a piecelist - 16 entries/side
; contains piece type, and piece square
; referencing 10x12 grid
; the BOARD is an 8x8 square in zp

    DEFINE_SUBROUTINE AddMove

    ; add square in y register to movelist as destination (0-63)
    ; currentPiexe = piece moving
    ; currentSquare = start square (0-63)

    ; To call (and this function MUST be at the start of every RAM bank)...
    ;       ldy #BANK_OF_CALLER
    ;       lda ply
    ;       sta SET_BANK_RAM
    ; and fall through ...

    DEFINE_SUBROUTINE InsertMove
        ; TODO - add move to movelist

                rts                 ; switch back to call bank and return



    include "Handler_QUEEN.asm"
    include "Handler_BISHOP.asm"
    include "Handler_ROOK.asm"
    include "Handler_KING.asm"


    OPTIONAL_PAGEBREAK "Base64ToIndex", 64
    DEFINE_SUBROUTINE Base64ToIndex
    ; Convert from 0-63 numbering into an index into the Chessboard

    .byte 22,23,24,25,26,27,28,29
    .byte 32,33,34,35,36,37,38,39
    .byte 42,43,44,45,46,47,48,49
    .byte 52,53,54,55,56,57,58,59
    .byte 62,63,64,65,66,67,68,69
    .byte 72,73,74,75,76,77,78,79
    .byte 82,83,84,85,86,87,88,89
    .byte 92,93,94,95,96,97,98,99


    CHECK_HALF_BANK_SIZE "HANDLER_BANK1 -- 1K"

;---------------------------------------------------------------------------------------------------
; EOF
