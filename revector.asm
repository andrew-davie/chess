; Insert this into the START of ALL RAM banks that add moves to the movelist
; It switches to the correct bank based on 'ply', and returns to the caller bank

    DEFINE_SUBROUTINE Return
                lda fromBank
                sta SET_BANK_RAM
                rts

    DEFINE_SUBROUTINE InitBank
                lda #BANK_COMMON_VARIABLES
                sta SET_BANK_RAM
                jmp Init_Bank

    DEFINE_SUBROUTINE AddMove

    ; To call (and this function MUST be at the start of every RAM bank)...
    ;       ldy #BANK_OF_CALLER
    ;       lda ply
    ;       sta SET_BANK_RAM
    ; and fall through ...

    DEFINE_SUBROUTINE InsertMove




                ldx MoveNumber

        ; TODO - add move to movelist
                ; sta MoveListFrom + RAM_WRITE,x

                inx
                stx MoveNumber + RAM_WRITE

                sty SET_BANK_RAM                    ; return to bank of move generator (i.e., KING MOVE)
                rts




; EOF
