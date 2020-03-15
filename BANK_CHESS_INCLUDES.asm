; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


; Each piece is defined as 3 PF bytes (horizontal) x 24 scanlines (vertical)
; The pieces are converted by ConvertChessPieces.py (in tools), which takes
; a single gif of the format..
; a row of white pieces on black squares
; a row of white pieces on white squares
; a row of black pieces on black squares
; a row of black pieces on white squares

; each row has the pieces ordered thus:
; a blank, then pawn, knight, bishop, rook, queen, king
; each piece is 5 pixels wide x 8 pixels deep
; each pixel is from an 8-colour palette.
; Given a pixel colour 0-7 (represented in binary 000 - 111) then if the bits
; for the colour are abc (i.e., colour #3 = binary 011 = bits 0bc)
; then bit "a" becomes the first interleaved chronocolour pixel (line 1)
; bit "b" becomes the second ICC pixel line (2)
; bit "c" becomes the third ICC pixel line (3)
; Thus, a 5 pxel x 8 pixel shape becomes 24 lines deep
; The tool produces 4 variants of the piece; shifted into the 4 squares
; in the PF - thus, at pixel 0, pixel 5, pixel 10, pixel 15.
; These 4 shifted positions are stored consecutively in the shape definition

; Example...
;DEF WHITE_BISHOP_on_BLACK_SQUARE_0
;.byte $00,$40,$40,$40,$00,$00,$e0,$e0,$e0,$d0,$d0,$d0,$b0,$b0,$b0,$f0,$f0,$f0,$e0,$60,$e0,$f0,$f0,$f0 ;PF0
;.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$80,$80,$00,$80,$80,$00,$80,$00,$00,$00,$00,$80,$00 ;PF1
;.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;PF2

; The above defines the three 24-byte vertical strips for the 3 PF bytes that
; the piece (could) overlay. In this case, on square 0 (leftmost), it doesn't
; actually have any data in PF1 or PF2.

    include "piece_graphics.asm"

;    NEWBANK PIECE_VECTORS
;    include "piece_vectors.asm"
;    CHECK_BANK_SIZE "PIECE_VECTORS (2K)"
