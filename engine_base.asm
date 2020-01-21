            NEWRAMBANK BANK_BASE_MOVE

; This is a basic structure bank holding everything for a single PLY
; So it's duplicated for the maximum numbe of PLYs

            include "add_move_switcher.asm"

    ; Here we have variables which are specific to a single PLY...

    OPTIONAL_PAGEBREAK MoveListFrom,16
MoveListFrom    ds 16

    OPTIONAL_PAGEBREAK MoveListTo,16
MoveListFrom    ds 16


MoveNumber      ds 1                    ; pointer for this ply to movelist

    MACRO INIT_PLY
            lda #0
            sta MoveNumber+RAM_WRITE
    ENDM

            CHECK_BANK_SIZE "ENGINE6502 -- full 2K"
