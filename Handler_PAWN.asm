; Copyright (C)2020 Andrew Davie
; Pawn move handlers

;---------------------------------------------------------------------------------------------------
; WHITE PAWN
;---------------------------------------------------------------------------------------------------

WHITE_HOME_ROW     = 40                    ; < this, on home row
BLACK_HOME_ROW     = 82                    ; >= this, on home row

;---------------------------------------------------------------------------------------------------

    MAC EN_PASSANT
    SUBROUTINE
    ; {1} = _LEFT or _RIGHT
                ldy ValidSquare+{1},x
                cpy enPassantPawn
                bne .invalid
                ldy ValidSquare+{1}+{2},x   ; en-passant endpoint must be blank
                lda Board,y
                bne .invalid
                jsr AddMove                 ; the MOVE will need to deal with the details of en-passant??
.invalid
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC PROMOTE_PAwN
    SUBROUTINE
    ;{1} = BLACK or WHITE

                lda currentPiece
                pha

                lda #{1}|QUEEN
                sta currentPiece
                jsr AddMove

                lda #{1}|ROOK
                sta currentPiece
                jsr AddMove

                lda #{1}|BISHOP
                sta currentPiece
                jsr AddMove

                lda #{1}|KNIGHT
                sta currentPiece
                jsr AddMove

                pla
                sta currentPiece
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC MOVE_OR_PROMOTE_PAWN
    SUBROUTINE
    ; {1} = BLACK or WHITE

        IF {1} = WHITE
                cpy #90                        ; last rank?
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

.standard       jsr AddMove                     ; add +1UP move
.pMoved

    ENDM

;---------------------------------------------------------------------------------------------------

    MAC TAKE
    SUBROUTINE
    ; {1} = capture square offset

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

    DEFINE_SUBROUTINE PromoteWhitePawn
                PROMOTE_PAWN WHITE
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_WHITE_PAWN

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

                jsr AddMove                     ; add the +2UP move off home row
                ldx currentSquare

.pMoved

    ; en-passant captures...

                lda enPassantPawn
                beq .noEnPassant

                EN_PASSANT _LEFT, _UP
                ldx currentSquare
                EN_PASSANT _RIGHT, _UP

.noEnPassant

    ; regular captures...

                TAKE _UP+_LEFT, WHITE
                ldx currentSquare
                TAKE _UP+_RIGHT, WHITE

                jmp MoveReturn


;---------------------------------------------------------------------------------------------------
; BLACK PAWN
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE PromoteBlackPawn
                PROMOTE_PAWN BLACK
                rts

    DEFINE_SUBROUTINE Handle_BLACK_PAWN
    SUBROUTINE

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

                jsr AddMove                     ; add the +2DOWN move off home row

.pMoved

    ; en-passant captures...

                lda enPassantPawn
                beq .noEnPassant

                EN_PASSANT _LEFT, _DOWN
                ldx currentSquare
                EN_PASSANT _RIGHT, _DOWN

.noEnPassant

    ; regular captures...

                TAKE _DOWN+_LEFT, BLACK
                ldx currentSquare
                TAKE _DOWN+_RIGHT, BLACK

Handle_BLANK    jmp MoveReturn

; EOF
