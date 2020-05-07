; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1 ; this code assembles for bank #1
    NEWBANK GENMOVE

    MAC HANDLEVEC
        .byte {1}MoveReturn
        .byte {1}MoveReturn ;byte {1}Handle_WHITE_PAWN        ; 1
        .byte {1}MoveReturn ;.byte {1}Handle_BLACK_PAWN        ; 2
        .byte {1}Handle_KNIGHT            ; 3
        .byte {1}Handle_BISHOP            ; 4
        .byte {1}Handle_ROOK              ; 5
        .byte {1}Handle_QUEEN             ; 6
        .byte {1}Handle_KING              ; 7

        .byte {1}MoveReturn
        .byte {1}Handle_WHITE_PAWN        ; 1
        .byte {1}Handle_BLACK_PAWN        ; 2
        .byte {1}MoveReturn;.byte {1}Handle_KNIGHT            ; 3
        .byte {1}MoveReturn;.byte {1}Handle_BISHOP            ; 4
        .byte {1}MoveReturn;.byte {1}Handle_ROOK              ; 5
        .byte {1}MoveReturn;.byte {1}Handle_QUEEN             ; 6
        .byte {1}MoveReturn;.byte {1}Handle_KING              ; 7
    ENDM


;    .byte 0     ; dummy to prevent page cross access on index 0

HandlerVectorLO     HANDLEVEC <
HandlerVectorHI     HANDLEVEC >
HandlerVectorBANK   HANDLEVEC BANK_


    include "Handler_BISHOP.asm"
    include "Handler_KING.asm"
    include "Handler_QUEEN.asm"

;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "GENMOVE"

;---------------------------------------------------------------------------------------------------
; EOF
