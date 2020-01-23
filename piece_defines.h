; Copyright (C)2020 Andrew Davie

BLACK               = 128
WHITE               = 0
PIECE_COLOUR        = 128               ; mask


MOVED               = 64                ; mark ALL pieces when moved. Used for castling
                                        ; but maybe useful for evaluation of development
PHANTOM             = 32                ; a phantom king (via castling)

;---------------------------------------------------------------------------------------------------
; DEFINE THE PIECES
; ID lives in bits 0-2

BLANK               = 0
WPAWN               = 1
BPAWN               = 2
KNIGHT              = 3
BISHOP              = 4
ROOK                = 5
QUEEN               = 6
KING                = 7

PIECE_MASK          = 7                 ; trim off the flags leaving just piece ID

;---------------------------------------------------------------------------------------------------

; Movements

_UP = 12        ; up
_LEFT = -1      ; left
_DOWN = -12     ; down
_RIGHT = 1      ; right

; EOF
