# ConvertChessPieces.py
# Andrew Davie andrew@taswegian.com

# This tool grabs chess piece definitions from a source image and converts to .asm source code
# The pieces are 5 pixels wide x 8 pixels deep.
# The source image is defined as (horizontally) blank / pawn / knight / bishop / rook / queen / king
# with the following structure:
# line 1: white pieces on black squares
# line 2: white pieces on white squares
# line 3: black pieces on black squares
# line 4: black pieces on white squares
# thus it's a 7 x 4 chessboard grid, with pieces on top
# The board is drawn with an 8-colour palette - colour 0 being black, and colours 1 2 and 4
# are the colours of three successive scanlines on the '2600. Groups of 3 scanlines form an
# 'interleaved chronocolour' (ICC) pixel.  This tool reads the pixel values and converts the palette
# colour into on/off pixels for three successive ICC sub-lines - forming the colour pixel.
# The upshot of this, you can't actually change the colours 3,5,6,7 - they are a result of mixing
# of colours 1, 2, 4
# The utility produces source .asm code in the form of 3 bytes per scanline x 24 scanlines per
# piece. The three bytes directly correspond to PF0 PF1 and PF2 on the '2600, so no shifting is
# required - they can be directly OR'd in to existing bitmap data for display.
# The shifting 'across' to put the piece in the correct horizontal square is done by the tool,
# but again, the shifting is within the 3 PF bytes, so it's just a direct OR'd in draw
# Piece definitions are written to individual files so that they can easily be located in
# multiple banks.

from PIL import Image
from enum import Enum

SQUARE_WIDTH = 5
SQUARE_HEIGHT = 8


class PieceColours(Enum):
    WHITE = 0
    BLACK = 1


class SquareColours(Enum):
    WHITE = 1
    BLACK = 0


class PieceTypes(Enum):
    BLANK = 0
    PAWN = 1
    KNIGHT = 3
    BISHOP = 4
    ROOK = 5
    QUEEN = 6
    KING = 7


pixel_no_to_bit_position = [
    1 << 20,
    1 << 21,
    1 << 22,
    1 << 23,

    1 << 15,
    1 << 14,
    1 << 13,
    1 << 12,
    1 << 11,
    1 << 10,
    1 << 9,
    1 << 8,

    1 << 0,
    1 << 1,
    1 << 2,
    1 << 3,
    1 << 4,
    1 << 5,
    1 << 6,
    1 << 7
]


def grab(pieces_bitmap, side_colour, square_colour, piece_type):

    y_start = (side_colour.value * 2 + square_colour.value) * SQUARE_HEIGHT
    x_start = piece_type.value * SQUARE_WIDTH

    for square_offset in range(0, 4):

        name = side_colour.name + "_" + piece_type.name + "_on_" + square_colour.name + "_SQUARE_" + str(square_offset)
        f = open(name + '.asm', 'w')
        f.write(name + "\n")

        pf = [[],[],[]]

        for y_bitmap in range(0, SQUARE_HEIGHT):

            icc_scanline = [0, 0, 0]

            for x_bitmap in range(0, SQUARE_WIDTH):

                pixel_icc_colour = pieces_bitmap[x_start + x_bitmap, y_start + y_bitmap]
                x_pf_pixel = x_bitmap + square_offset * SQUARE_WIDTH

                if (pixel_icc_colour & 4) != 0:
                    icc_scanline[0] |= pixel_no_to_bit_position[x_pf_pixel]
                if (pixel_icc_colour & 2) != 0:
                    icc_scanline[1] |= pixel_no_to_bit_position[x_pf_pixel]
                if (pixel_icc_colour & 1) != 0:
                    icc_scanline[2] |= pixel_no_to_bit_position[x_pf_pixel]

            # Now output the three scanlines' playfield bytes
            # we are not worrying about minimising ROM here - just 3 bytes/definition

            for scanline in range(0, 3):

                pf[0].append((icc_scanline[scanline] >> 16) & 0xFF)
                pf[1].append((icc_scanline[scanline] >> 8) & 0xFF)
                pf[2].append((icc_scanline[scanline]) & 0xFF)

        # write the three 'columns' PF0, PF1, PF2
        # columns make it easier to access/draw using Y as an index to indirect pointers to columns

        for playfield in range(0, 3):
            f.write(' .byte ' + ','.join(f'${x:02x}' for x in pf[playfield])
                    + ' ;PF' + str(playfield) + '\n')

        f.close()


im = Image.open("pieces.gif")
pix = im.load()

for side in PieceColours:
    for square in SquareColours:
        for piece in PieceTypes:
            grab(pix, side, square, piece)
