    processor 6502
    org $1000

    MAC LO
    .byte <{1}
    ENDM

    MAC HI
    .byte >{1}
    ENDM


    MAC TABDEF ; {1} = macro to use
        ; and per-line, {1} = function
    {1}  Func1
    {1}  Func2
    {1}  Func3
    ENDM

LO_Table
    TABDEF LO
HI_Table
    TABDEF HI


Func1
    rts

Func2
    rts

Func3
    rts
