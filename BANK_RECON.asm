    NEWBANK RECON

;---------------------------------------------------------------------------------------------------

    DEF UNSAFE_showMoveCaptures
    SUBROUTINE

        VAR __toSquareX12, 1
        VAR __fromPiece, 1
        VAR __aiMoveIndex, 1

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked

                    lda savedBank
                    pha

                    lda #BANK_UNSAFE_showMoveCaptures
                    sta savedBank


.next               ldx aiMoveIndex
                    stx __aiMoveIndex
                    bmi .skip                       ; no moves in list

                    dec aiMoveIndex

                    jsr GetMoveFrom
                    cmp aiFromSquareX12
                    bne .next


                    jsr GetMoveTo
                    sta __toSquareX12
                    tay
                    jsr GetBoard
                    and #PIECE_MASK
                    beq .next

    ; There's something on the board at destination, so it's a capture
    ; Let's see if we are doing a pawn promote...

                    ldy aiFromSquareX12
                    jsr GetBoard
                    sta __fromPiece

                    jsr GetMovePiece
                    eor __fromPiece
                    and #PIECE_MASK
                    beq .legit                  ; from == to, so not a promote

    ; Have detected a promotion duplicate - skip all 3 of them

                    dec aiMoveIndex                 ; skip "KBRQ" promotes
                    dec aiMoveIndex
                    dec aiMoveIndex

.legit

        TIMECHECK COPYSINGLEPIECE, restoreIndex     ; not enough time to draw

                    lda __toSquareX12
                    sta drawPieceNumberX12

                    jsr SAFE_CopySinglePiece

.skip               pla
                    sta savedBank
                    rts

restoreIndex        lda __aiMoveIndex
                    sta aiMoveIndex
                    jmp .skip


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetA
    SUBROUTINE

        VAR __fromRow, 1
        VAR __boardIndex, 1
        VAR __fromCol, 1
        VAR __toCol, 1


    ; Now we calculate move to new square

                    lda fromX12
                    cmp toX12
                    beq .unmovedx
                    sta lastSquareX12

                    sec
                    ldx #-3
.sub10              sbc #10
                    inx
                    bcs .sub10
                    adc #8
                    sta __fromCol
                    stx __fromRow

                    lda toX12
                    sec
                    ldx #-3
.sub10b             sbc #10
                    inx
                    bcs .sub10b
                    adc #8
                    sta __toCol


                    cpx __fromRow
                    beq .rowDone

                    bcs .incRow

                    sec
                    lda fromX12
                    sbc #10
                    sta fromX12
                    jmp .rowDone

.incRow             clc
                    lda fromX12
                    adc #10
                    sta fromX12

.rowDone

                    lda __toCol
                    cmp __fromCol
                    beq .colDone

                    bcs .incCol

                    dec fromX12
                    jmp .colDone

.incCol             inc fromX12
.colDone




    ; erase object in new sqare --> blank

                    ldy fromX12
                    sty drawPieceNumberX12

                    jsr GetBoard
                    cmp #0
                    beq .skipbl
                    jsr SAFE_CopySinglePiece             ; erase next square along --> blank

.skipbl
                    ldy fromX12
                    sty __boardIndex

                    jsr GetBoard
                    sta lastPiece                   ; what we are overwriting
                    lda fromPiece
                    ;ora #FLAG_MOVED                 ; prevents usage in castling for K/R
                    and #~FLAG_ENPASSANT
                    ldy __boardIndex
                    jsr PutBoard

                    PHASE AI_MarchB

.unmovedx
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB2
    SUBROUTINE

                    ldy lastSquareX12
                    sty drawPieceNumberX12

                    jsr GetBoard
                    cmp #0
                    beq .skipbl2

                    jsr SAFE_CopySinglePiece             ; draw previous piece back in old position
.skipbl2

                    lda fromX12
                    cmp toX12
                    beq xhalt

                    lda #0                          ; inter-move segment speed (can be 0)
                    sta drawDelay
                    PHASE AI_MarchToTargetA

                    rts

xhalt

                    jsr FinaliseMove

                    lda #4                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE AI_FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------

    DEF FinaliseMove
    SUBROUTINE

    ; Now the visible movement on the board has happened, fix up the pointers to the pieces
    ; for both sides.

                    lda #BANK_FinaliseMove
                    sta savedBank

                    lda sideToMove
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    jsr GoFixPieceList

                    lda toX12
                    sta fromX12                     ; there MAY be no other-side piece at this square - that is OK!
                    sta originX12

                    lda #0
                    sta toX12                       ; --> deleted (square=0)

                    lda lastPiece
                    beq .notake

                    lda sideToMove
                    eor #128
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    jsr GoFixPieceList                ; REMOVE any captured object

.notake             rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

    ; now we want to undraw the piece in the old square

                    lda lastSquareX12
                    sta drawPieceNumberX12

                    jsr SAFE_CopySinglePiece        ; erase whatever was on the previous square (completely blank)

                    ldy lastSquareX12
                    lda previousPiece
                    jsr PutBoard

                    lda lastPiece
                    sta previousPiece

                    PHASE AI_MarchB2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiGenerateMoves
    SUBROUTINE

                    jsr GenerateOneMove
                    bcc .wait

                    ;lda currentPly
                    ;sta SET_BANK_RAM
                    ;jsr alphaBeta

    #if PVSP
        jmp .player ;tmp
    #endif

                    ldx sideToMove
                    bpl .player


.computer           PHASE AI_ComputerMove               ; computer select move
                    rts


.player             PHASE AI_StartMoveGen
.wait               rts


;---------------------------------------------------------------------------------------------------



;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_RECON"

; EOF
