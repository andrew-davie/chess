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


TOOL = "; Created by ConvertChessPieces.py\n"
BANK_SIZE = 2048

SQUARE_WIDTH = 5
SQUARE_HEIGHT = 8



class PieceColours(Enum):
    WHITE = 0
    BLACK = 1
#    WHITE_MARKED = 2
#    BLACK_MARKED = 3


class SquareColours(Enum):
    WHITE = 1
    BLACK = 0


class PieceTypes(Enum):
    BLANK = 0
    PAWN = 1
    KNIGHT = 2
    BISHOP = 3
    ROOK = 4
    QUEEN = 5
    KING = 6
    MARKER = 7
    PROMOTE = 8


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


def grab(pieces_bitmap, side_colour, square_colour, piece_type, wrapper, indexer):

    y_start = (side_colour.value * 2 + square_colour.value) * SQUARE_HEIGHT
    x_start = piece_type.value * SQUARE_WIDTH

    for square_offset in range(0, 4):

        name = side_colour.name + "_" + piece_type.name + "_on_" + square_colour.name + "_SQUARE_" + str(square_offset)
        f = open(name + '.asm', 'w')
        f.write(' OPTIONAL_PAGEBREAK "' + name + '", 72\n')
        f.write(' DEF ' + name + "\n")

        lo.append(' .byte <' + name + '\n')
        hi.append(' .byte >' + name + '\n')
        bank.append(' .byte BANK_' + name + '\n')

        equate.append('INDEX_'+name + '=' + str(indexer) + '\n')
        indexer += 1

        wrapper += 1
        if wrapper % 28 == 0:
            f_includes.write('   CHECK_BANK_SIZE "CHESS_PIECES_' + str(int((wrap / 28 - 1))) + ' ; -- full 2K"\n')
            f_includes.write(' NEWBANK CHESS_PIECES_' + str(int(wrap / 28)) + '\n')

        f_includes.write(" include \"gfx/" + name + ".asm\"\n")

        pf = [[],[],[]]

        for y_bitmap in range(0, SQUARE_HEIGHT):

            icc_scanline = [0, 0, 0]

            for x_bitmap in range(0, SQUARE_WIDTH):

                pixel_icc_colour = pieces_bitmap[x_start + x_bitmap, y_start + y_bitmap]
                #if piece_type != PieceTypes.BLANK:
                #    pixel_icc_colour ^= pieces_bitmap[x_bitmap, y_start + y_bitmap]
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

        mangled = [[],[],[]]
        for line in range(0, 24, 3):
            mangled[0].append(pf[0][line])
            mangled[1].append(pf[1][line])
            mangled[2].append(pf[2][line])
        for line in range(0, 24, 3):
            mangled[0].append(pf[0][line+1])
            mangled[1].append(pf[1][line+1])
            mangled[2].append(pf[2][line+1])
        for line in range(0, 24, 3):
            mangled[0].append(pf[0][line+2])
            mangled[1].append(pf[1][line+2])
            mangled[2].append(pf[2][line+2])

        mangled2 = [[],[],[]]
        for block in range(0, 3):
            for line in range(7, -1, -1):
                mangled2[0].append(mangled[0][block*8+line])
                mangled2[1].append(mangled[1][block*8+line])
                mangled2[2].append(mangled[2][block*8+line])

        for playfield in range(0, 3):
            f.write(' .byte ' + ','.join(f'${x:02x}' for x in mangled2[playfield])
                    + ' ;PF' + str(playfield) + '\n')

        f.close()

print("Converting chess pieces")

im = Image.open("pieces.gif")
pix = im.load()

f_includes = open('../piece_includes.asm', 'w')
f_includes.write(TOOL)

f_vector = open('../piece_vectors.asm', 'w')
f_vector.write(TOOL)

wrap = 0

lo = []
hi = []
bank = []
equate = []

index = 0

for side in PieceColours:
    for square in SquareColours:
        for piece in PieceTypes:
            grab(pix, side, square, piece, wrap, index)
            index += 4

f_vector.write(' DEF PIECE_VECTOR_LO\n')
for low_ptr in lo:
    f_vector.write(low_ptr)

f_vector.write(' DEF PIECE_VECTOR_HI\n')
for high_ptr in hi:
    f_vector.write(high_ptr)

f_vector.write(' DEF PIECE_VECTOR_BANK\n')
for bank_ptr in bank:
    f_vector.write(bank_ptr)

f_vector.write('\n; piece index equates...\n')
for equ in equate:
    f_vector.write(equ)

f_vector.close()
