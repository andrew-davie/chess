
            NEWBANK GENERIC_BANK_2

    IF ENPASSANT_ENABLED

    DEF EnPassantCheck
    SUBROUTINE

        REFER MakeMove
        REFER aiSpecialMoveFixup
        VEND EnPassantCheck

    ; {
    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

                    ldy enPassantPawn               ; save from previous side move

                    ldx #0                          ; (probably) NO en-passant this time
                    lda fromPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    eor fromPiece                   ; clear FLAG_ENPASSANT
                    sta fromPiece

                    ldx fromX12                     ; this IS an en-passantable opening, so record the square
.noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

    ; }


    ; Check to see if we are doing an actual en-passant capture...

    ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
    ;  as the en-passant will fail if the taking piece does not have this flag set correctly

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece


    ; {

    ; Here we are the aggressor and we need to take the pawn 'en passant' fashion
    ; y = the square containing the pawn to capture (i.e., previous value of 'enPassantPawn')

    ; Remove the pawn from the board and piecelist, and undraw

                    sty squareToDraw
                    jsr CopySinglePiece             ; undraw captured pawn

                    lda #RAMBANK_BANK_EVAL
                    sta SET_BANK_RAM
                    sta savedBank

                    ldy originX12                   ; taken pawn's square
                    jsr EnPassantRemovePiece

.notEnPassant
    ; }

                    rts

    ENDIF
    

            CHECK_BANK_SIZE "GENERIC_BANK_2 -- full 2K"
