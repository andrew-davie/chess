    processor 6502
    org $1000

    MAC TEST3
        lda #0
    ENDM

    MAC TEST2
        TEST3
    ENDM


    MAC TEST1
        TEST2
    ENDM


    MAC TEST0
        TEST1
    ENDM


    TEST0

;eof
