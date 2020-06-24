;enpassant stuff

; generic2...


;     DEF EnPassantCheck
;     SUBROUTINE

;         REF MakeMove ;✅
;         REF aiSpecialMoveFixup ;✅
;         VEND EnPassantCheck


;     ; Generate secondary move for the captured pawn, involved in en passant
;     ; Returns:
;     ;   CC --> not a castle/secondary
;     ;   CS --> secondary move valid


;     ; {
;     ; With en-passant flag, it is essentially dual-use.
;     ; First, it marks if the move is *involved* somehow in an en-passant
;     ; if the piece has MOVED already, then it's an en-passant capture
;     ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

;                     ldy enPassantPawn               ; save from previous side move

;                     ldx #0                          ; (probably) NO en-passant this time
;                     lda fromPiece
;                     and #FLAG_ENPASSANT|FLAG_MOVED
;                     cmp #FLAG_ENPASSANT
;                     bne .noep                       ; HAS moved, or not en-passant

;                     eor fromPiece                   ; clear FLAG_ENPASSANT
;                     sta fromPiece

;                     ldx toX12                       ; this IS an en-passantable opening, so record the square
; .noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

;     ; }

;                     CALL GenEnPassantMove

;     ; Check to see if we are doing an actual en-passant capture...

;     ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
;     ;  as the en-passant will fail if the taking piece does not have this flag set correctly

;                     lda fromPiece
;                     and #FLAG_ENPASSANT
;                     beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece


;     ; at this point the attacking pawn has finished moving to the "take" square
;     ; the loser-pawn is marked with enPassantPawn
;     ; we want to generate a 'blank' move to take the pawn

;                     lda originX12                   ; we need a blank square to move FROM
;                     sta fromX12                     ; use the square the attacker pawn just left

;     ; calculate the captured pawn's square based on move colour

;                     lda #-10
;                     ldx fromPiece
;                     bpl .white
;                     lda #10
; .white
;                     clc
;                     adc fromX12                     ; attacker destination square
;                     sta toX12                       ; now we have the captured pawn square!
;                     sta@PLY secondarySquare         ; square to which we RESTORE the captured pawn on unmakemove

;                     sta@PLY secondaryBlank
;                     lda fromPiece
;                     eor #$80                        ; opponent pawn
;                     sta@PLY secondaryPiece          ; a capture!

;                     ;SWAP                            ; double - so we don't swap

;     ; in this siutation (en passant, capture happening) we do not change sides yet!

;                     PHASE MoveIsSelected
                    
; .notEnPassant       rts


    
    


;     IF 0
;     ; {

;     ; Here we are the aggressor and we need to take the pawn 'en passant' fashion
;     ; y = the square containing the pawn to capture (i.e., previous value of 'enPassantPawn')

;     ; Remove the pawn from the board and piecelist, and undraw

;                     sty squareToDraw

;     ; WARNING - local variables will not survive the following call...!
;                     jsr CopySinglePiece;@0          ; undraw captured pawn

;                     lda #EVAL
;                     sta SET_BANK;@3

;                     ldy originX12                   ; taken pawn's square
;                     jsr EnPassantRemovePiece;@2

; .notEnPassant
;     ; }
;     ENDIF


;                     rts

;     ENDIF
    

;---------------------------------------------------------------------------------------------------

    IF 0
    DEF EnPassantRemovePiece
    SUBROUTINE

        REF MakeMove

    IF ENPASSANT_ENABLED
        ; REF EnPassantCheck ;✅
    ENDIF

        VAR __y, 1
        VAR __col, 1

        VEND EnPassantRemovePiece


    ; Based on piece square, adjust material and position value with piece deleted
    ; y = piece square

                    sty __y

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    sta __col
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; (same bank) adding for opponent = taking
                    
                    rts
    ENDIF

;negamax@1

    IF ENPASSANT_ENABLED

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

                    ldx toX12                       ; this IS an en-passantable opening, so record the square
.noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

    ; }

    ; TODO: y = previous enpassantpawn value - use!


                    ;CALL GenCastleMoveForRook_ENPASSANT;@2
                    ;bcs .move                       ; "move" the blank to capture the pawn
    ENDIF

    