; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 3 ; this code assembles for bank #1
    NEWBANK THREE

;---------------------------------------------------------------------------------------------------

    DEF GetPiece
    SUBROUTINE

        REFER aiSelectDestinationSquare
        REFER aiQuiescent
        VEND GetPiece

    ; Retrieve the piece+flags from the movelist, given from/to squares
    ; Required as moves have different flags but same origin squares (e.g., castling)

                    lda currentPly
                    sta SET_BANK_RAM;@2

    ; returns piece in A+fromPiece
    ; or Y=-1 if not found

    ; We need to get the piece from the movelist because it contains flags (e.g., castling) about
    ; the move. We need to do from/to checks because moves can have multiple origin/desinations.
    ; This fixes the move with/without castle flag


                    ldy@PLY moveIndex
                    bmi .fail                       ; shouldn't happen

.scan               lda fromX12
                    cmp@PLY MoveFrom,y
                    bne .next
                    lda toX12                    
                    cmp@PLY MoveTo,y
                    beq .found
.next               dey
                    bpl .scan
.fail               rts

.found              lda@PLY MovePiece,y
                    sta fromPiece

                    rts


;---------------------------------------------------------------------------------------------------

    
    DEF selectmove
    SUBROUTINE

        COMMON_VARS_ALPHABETA
        REFER aiComputerMove
        VEND selectmove



    ; RAM bank already switched in!!!
    ; returns with RAM bank switched


        IF DIAGNOSTICS
        
                    lda #0
                    sta positionCount
                    sta positionCount+1
                    sta positionCount+2
                    ;sta maxPly
        ENDIF


                    lda #<INFINITY
                    sta __beta
                    lda #>INFINITY
                    sta __beta+1

                    lda #<-INFINITY
                    sta __alpha
                    lda #>-INFINITY
                    sta __alpha+1                   ; player tries to maximise

                    ldx #SEARCH_DEPTH  
                    lda #0                          ; no captured piece
                    sta __quiesceCapOnly            ; ALL moves to be generated

                    ;tmp jsr negaMax
 
                    ldx@PLY bestMove
                    bmi .nomove

    ; Generate player's moves in reply
    ; Make the computer move, list player moves (PLY+1), unmake computer move

                    stx@PLY movePtr
                    CALL MakeMove;@1
                    jsr ListPlayerMoves;@0
                    jsr unmakeMove;@0

    ; Grab the computer move details for the UI animation

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM

                    ldx@PLY bestMove
                    lda@PLY MoveTo,x
                    sta toX12
                    lda@PLY MoveFrom,x
                    sta originX12
                    sta fromX12
                    lda@PLY MovePiece,x
                    sta fromPiece

.nomove
                    rts



;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_3"

;---------------------------------------------------------------------------------------------------
; EOF
