; Copyright (C)2020 Andrew Davie
; Piece movement handlers bank 1

;---------------------------------------------------------------------------------------------------

    NEWRAMBANK HANDLER_BANK1

    include "common_vectors.asm"         ; MUST BE FIRST
    include "Handler_MACROS.asm"

    include "Handler_KING.asm"
    include "Handler_KNIGHT.asm"
    include "Handler_PAWN.asm"

    CHECK_HALF_BANK_SIZE "HANDLER_BANK1 -- 1K"

;---------------------------------------------------------------------------------------------------
; EOF
