; Copyright (C)2020 Andrew Davie

BLACK               = 128
WHITE               = 0

PIECE_COLOUR        = 128               ; mask
MOVED               = 64                ; mark ALL pieces when moved. Used for castling
                                        ; but maybe useful for evaluation of development
ENPASSANT           = 32
CASTLE              = 16

;PHANTOM             = 32                ; a phantom king (via castling)  -- requires bigger movelist OR DOES IT
;HELPER              = 16

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

PIECE_MASK          = 7                 ; trim off the flags leaving just piece ID

;---------------------------------------------------------------------------------------------------

; Movements

_UP = 10        ; up
_LEFT = -1      ; left
_DOWN = -10     ; down
_RIGHT = 1      ; right

; EOF
