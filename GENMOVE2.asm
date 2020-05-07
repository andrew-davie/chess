; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1 ; this code assembles for bank #1
    NEWBANK GENMOVE2

    include "Handler_ROOK.asm"
    include "Handler_KNIGHT.asm"
    include "Handler_PAWN.asm"

;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "GENMOVE2"

;---------------------------------------------------------------------------------------------------
; EOF
