; Copyright (C)2020 Andrew Davie

BLACK               = 128
WHITE               = 0

FLAG_COLOUR         = 128               ; mask
FLAG_MOVED          = 64                ; mark ALL pieces when moved. Used for castling
                                        ; but maybe useful for evaluation of development
FLAG_ENPASSANT      = 32
FLAG_CASTLE         = 16

;---------------------------------------------------------------------------------------------------
; DEFINE THE PIECES
; ID lives in bits 0-2

BLANK               = 0
███                 = BLANK

WPAWN               = 1
WP                  = WPAWN
BPAWN               = 2
BP                  = BPAWN
KNIGHT              = 3
N                   = KNIGHT
BISHOP              = 4
B                   = BISHOP
ROOK                = 5
R                   = ROOK
QUEEN               = 6
Q                   = QUEEN
KING                = 7
K                   = KING
MARKER              = 8

PIECE_MASK          = 15                 ; trim off the flags leaving just piece ID

;---------------------------------------------------------------------------------------------------

; Movements

_UP = 10        ; up
_LEFT = -1      ; left
_DOWN = -10     ; down
_RIGHT = 1      ; right

; EOF
