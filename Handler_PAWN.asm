; Copyright (C)2020 Andrew Davie
; Pawn move handlers

;---------------------------------------------------------------------------------------------------
; WHITE PAWN
;---------------------------------------------------------------------------------------------------

WHITE_HOME_ROW     = 40                             ; < this, on home row
BLACK_HOME_ROW     = 82                             ; >= this, on home row

;---------------------------------------------------------------------------------------------------

    MAC EN_PASSANT
    SUBROUTINE
    ; {1} = _LEFT or _RIGHT

                    ldx currentSquare
                    ldy ValidSquare+{1},x
                    cpy enPassantPawn
                    bne .invalid
                    ldy ValidSquare+{1}+{2},x       ; en-passant endpoint must be blank
                    lda Board,y
                    bne .invalid
                    jsr AddMove                     ; the MOVE will need to deal with the details of en-passant??
.invalid
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC PROMOTE_PAwN
    ;SUBROUTINE

    ;{1} = BLACK or WHITE


                    sty __temp
                    lda #{1}|QUEEN
                    sta currentPiece
                    jsr AddMove

                    lda #{1}|ROOK
                    sta currentPiece
                    ldy __temp
                    jsr AddMove

                    lda #{1}|BISHOP
                    sta currentPiece
                    ldy __temp
                    jsr AddMove

                    lda #{1}|KNIGHT
                    sta currentPiece
                    ldy __temp
                    jsr AddMove

        IF {1} = WHITE
                    lda #WHITE|WP
        ENDIF
        IF {1} = BLACK
                    lda #BLACK|BP
        ENDIF
                    sta currentPiece
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC MOVE_OR_PROMOTE_PAWN
    ;SUBROUTINE
    ; {1} = BLACK or WHITE

        IF {1} = WHITE
                    cpy #90                         ; last rank?
                    bcc .standard
                    jsr PromoteWhitePawn
                    jmp .pMoved
        ENDIF

        IF {1} = BLACK
                    cpy #30                         ; last rank?
                    bcs .standard
                    jsr PromoteBlackPawn
                    jmp .pMoved
        ENDIF

.standard           jsr AddMove                     ; add +1UP move
.pMoved

    ENDM

;---------------------------------------------------------------------------------------------------

    MAC TAKE
    ;SUBROUTINE
    ; {1} = capture square offset

                    ldx currentSquare
                    ldy ValidSquare+{1},x
                    bmi .invalid
                    lda Board,y
                    beq .invalid                    ; square empty
                    eor currentPiece
                    bpl .invalid                    ; same colour

                    MOVE_OR_PROMOTE_PAWN {2}
.invalid
    ENDM

;---------------------------------------------------------------------------------------------------

    DEF PromoteWhitePawn
    SUBROUTINE

        REFER Handle_WHITE_PAWN
        VAR __temp, 1
        VEND PromoteWhitePawn

                    PROMOTE_PAWN WHITE
                    rts

;---------------------------------------------------------------------------------------------------

    DEF Handle_WHITE_PAWN
    SUBROUTINE

        REFER GenerateAllMoves
        VEND Handle_WHITE_PAWN
        
                    ldy ValidSquare+_UP,x           ; square above must be blank (WILL NOT EVER be off-board!)
                    lda Board,y
                    bne .pMoved                     ; occupied

    ; we may need to promote the pawn
    ; All possibilites (Q/R/B/N) are added as individual moves

                    MOVE_OR_PROMOTE_PAWN WHITE

    ; the +2 move off the home rank...

                    ldx currentSquare
                    cpx #WHITE_HOME_ROW
                    bcs .pMoved                     ; pawn has moved so can't do +2
                    ldy ValidSquare+_UP+_UP,x       ; WILL be a valid square
                    lda Board,y
                    bne .pMoved                     ; destination square occupied

                    lda currentPiece
                    ora #FLAG_ENPASSANT
                    sta currentPiece                ; GENERATE en-passant opportunity

                    jsr AddMove                     ; add the +2UP move off home row

.pMoved

    ; regular captures...

                    TAKE _UP+_LEFT, WHITE
                    TAKE _UP+_RIGHT, WHITE


    IF ENPASSANT_ENABLED
    ; en-passant captures...

                    lda enPassantPawn
                    beq .noEnPassant                ; previous move (opponent) enpassant square?

                    lda currentPiece
                    ora #FLAG_ENPASSANT
                    sta currentPiece                ; CONSUME en-passant opportunity

                    EN_PASSANT _LEFT, _UP
                    EN_PASSANT _RIGHT, _UP

.noEnPassant
    ENDIF

                    jmp MoveReturn


;---------------------------------------------------------------------------------------------------
; BLACK PAWN
;---------------------------------------------------------------------------------------------------

    DEF PromoteBlackPawn
    SUBROUTINE
    
        REFER Handle_BLACK_PAWN
        VAR __temp, 1
        VEND PromoteBlackPawn

                PROMOTE_PAWN BLACK
                rts

    DEF Handle_BLACK_PAWN
    SUBROUTINE

        REFER GenerateAllMoves
        VEND Handle_BLACK_PAWN

                ldy ValidSquare+_DOWN,x         ; square below must be blank (WILL NOT EVER be off-board!)
                lda Board,y
                bne .pMoved                     ; occupied


    ; we may need to promote the pawn
    ; All possibilites (Q/R/B/N) are added as individual moves

                MOVE_OR_PROMOTE_PAWN BLACK

    ; the +2 move off the home rank...

                ldx currentSquare
                cpx #BLACK_HOME_ROW
                bcc .pMoved                     ; pawn has moved so can't do +2


                ldy ValidSquare+_DOWN+_DOWN,x   ; WILL be a valid square
                lda Board,y
                bne .pMoved                     ; destination square occupied

                lda currentPiece
                ora #FLAG_ENPASSANT
                sta currentPiece                ; CAN en-passant

                jsr AddMove                     ; add the +2DOWN move off home row

.pMoved

    ; regular captures... (with promotion)

                TAKE _DOWN+_LEFT, BLACK
                TAKE _DOWN+_RIGHT, BLACK


    IF ENPASSANT_ENABLED
    ; en-passant captures...

                lda enPassantPawn
                beq .noEnPassant                    ; was last move en-passantable?

                lda currentPiece
                ora #FLAG_ENPASSANT
                sta currentPiece                    ; any en-passant move added will have flag set

                EN_PASSANT _LEFT, _DOWN
                EN_PASSANT _RIGHT, _DOWN

.noEnPassant
    ENDIF

                jmp MoveReturn

; EOF
