; Copyright (C)2020 Andrew Davie
; Piece movement handlers bank 2

;---------------------------------------------------------------------------------------------------

    NEWRAMBANK HANDLER_BANK1

    include "common_vectors.asm"         ; MUST BE FIRST
    include "Handler_MACROS.asm"

    include "Handler_QUEEN.asm"
    include "Handler_BISHOP.asm"
    include "Handler_ROOK.asm"

    CHECK_HALF_BANK_SIZE "HANDLER_MOVE2 -- 1K"

;---------------------------------------------------------------------------------------------------
; EOF
