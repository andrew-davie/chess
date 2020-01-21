; Copyright (C)2020 Andrew Davie

;---------------------------------------------------------------------------------------------------

    OPTIONAL_PAGEBREAK "ValidSquare", 144
    SUBROUTINE
    DEFINE_SUBROUTINE ValidSquare

    ; Use this table to
    ;   a) Determine if a square is valid (-1 = NO)
    ;   b) Move pieces without addition.  e.g., "lda ValidSquareTable+12,x" will let you know
    ;      if a white pawn on square "x" can move up the board.

    .byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    .byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    .byte -1,-1, 26, 27, 28, 29, 30, 31, 32, 33,-1,-1
    .byte -1,-1, 38, 39, 40, 41, 42, 43, 44, 45,-1,-1
    .byte -1,-1, 50, 51, 52, 53, 54, 55, 56, 57,-1,-1
    .byte -1,-1, 62, 63, 64, 65, 66, 67, 68, 69,-1,-1
    .byte -1,-1, 74, 75, 76, 77, 78, 79, 80, 81,-1,-1
    .byte -1,-1, 86, 87, 88, 89, 90, 91, 92, 93,-1,-1
    .byte -1,-1, 98, 99,100,101,102,103,104,105,-1,-1
    .byte -1,-1,110,111,112,113,114,115,116,117,-1,-1
    .byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
    .byte -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Return
                ldy returnBank
                sty SET_BANK_RAM
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE AddMove

    ; add square in y register to movelist as destinatio
    ; currentPiexe = piece moving
    ; currentSquare = start square

    ; To call (and this function MUST be at the start of every RAM bank)...
    ;       ldy #BANK_OF_CALLER
    ;       lda ply
    ;       sta SET_BANK_RAM
    ; and fall through ...

    DEFINE_SUBROUTINE InsertMove




        ; TODO - add move to movelist

                jmp Return                  ; switch back to call bank and return

;---------------------------------------------------------------------------------------------------
; EOF
