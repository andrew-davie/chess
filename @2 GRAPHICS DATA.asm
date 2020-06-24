;---------------------------------------------------------------------------------------------------
; @2 GRAPHICS DATA.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 2


;---------------------------------------------------------------------------------------------------

    ROMBANK GFX1

    include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_PROMOTE_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_PROMOTE_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_MARKER_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_MARKER_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_MARKER_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_MARKER_on_BLACK_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK GFX2

    include "gfx/WHITE_MARKER_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_MARKER_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_MARKER_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_ROOK_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_ROOK_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_ROOK_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_ROOK_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_0.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK GFX3

    include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_KING_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_KING_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_KING_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_KING_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_MARKER_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_MARKER_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_MARKER_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_MARKER_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_MARKER_on_BLACK_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK GFX4

    include "gfx/BLACK_MARKER_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_MARKER_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_MARKER_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_MARKER_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_PROMOTE_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_PROMOTE_on_WHITE_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECES_0

    include "gfx/WHITE_BLANK_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_BLANK_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_BLANK_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_BLANK_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_PAWN_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_PAWN_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_PAWN_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_PAWN_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_KNIGHT_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_KNIGHT_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_KNIGHT_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_KNIGHT_on_WHITE_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECES_1

    include "gfx/WHITE_BISHOP_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_BISHOP_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_BISHOP_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_BISHOP_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_ROOK_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_ROOK_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_ROOK_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_ROOK_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_QUEEN_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_QUEEN_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_QUEEN_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_QUEEN_on_WHITE_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECES_2

    include "gfx/WHITE_KING_on_WHITE_SQUARE_0.asm"
    include "gfx/WHITE_KING_on_WHITE_SQUARE_1.asm"
    include "gfx/WHITE_KING_on_WHITE_SQUARE_2.asm"
    include "gfx/WHITE_KING_on_WHITE_SQUARE_3.asm"
    include "gfx/WHITE_BLANK_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_BLANK_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_BLANK_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_BLANK_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_PAWN_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_PAWN_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_PAWN_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_PAWN_on_BLACK_SQUARE_3.asm"

    END_BANK


 ;---------------------------------------------------------------------------------------------------

    ROMBANK PIECES_3

    include "gfx/WHITE_KNIGHT_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_KNIGHT_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_KNIGHT_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_KNIGHT_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_BISHOP_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_BISHOP_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_BISHOP_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_BISHOP_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_ROOK_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_ROOK_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_ROOK_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_ROOK_on_BLACK_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECE_4

    include "gfx/WHITE_QUEEN_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_QUEEN_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_QUEEN_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_QUEEN_on_BLACK_SQUARE_3.asm"
    include "gfx/WHITE_KING_on_BLACK_SQUARE_0.asm"
    include "gfx/WHITE_KING_on_BLACK_SQUARE_1.asm"
    include "gfx/WHITE_KING_on_BLACK_SQUARE_2.asm"
    include "gfx/WHITE_KING_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_BLANK_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_BLANK_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_BLANK_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_BLANK_on_WHITE_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECE_5

    include "gfx/BLACK_PAWN_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_PAWN_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_PAWN_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_PAWN_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_KNIGHT_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_KNIGHT_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_KNIGHT_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_KNIGHT_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_BISHOP_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_BISHOP_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_BISHOP_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_BISHOP_on_WHITE_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECE_6

    include "gfx/BLACK_ROOK_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_ROOK_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_ROOK_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_ROOK_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_QUEEN_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_QUEEN_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_QUEEN_on_WHITE_SQUARE_2.asm"
    include "gfx/BLACK_QUEEN_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_KING_on_WHITE_SQUARE_0.asm"
    include "gfx/BLACK_KING_on_WHITE_SQUARE_1.asm"
    include "gfx/BLACK_KING_on_WHITE_SQUARE_2.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECE_7

    include "gfx/BLACK_KING_on_WHITE_SQUARE_3.asm"
    include "gfx/BLACK_BLANK_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_BLANK_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_BLANK_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_BLANK_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_PAWN_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_PAWN_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_PAWN_on_BLACK_SQUARE_2.asm"
    include "gfx/BLACK_PAWN_on_BLACK_SQUARE_3.asm"
    include "gfx/BLACK_KNIGHT_on_BLACK_SQUARE_0.asm"
    include "gfx/BLACK_KNIGHT_on_BLACK_SQUARE_1.asm"
    include "gfx/BLACK_KNIGHT_on_BLACK_SQUARE_2.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------

    ROMBANK PIECE_8

    include "gfx/BLACK_KNIGHT_on_BLACK_SQUARE_3.asm"

    END_BANK


;---------------------------------------------------------------------------------------------------
;EOF
