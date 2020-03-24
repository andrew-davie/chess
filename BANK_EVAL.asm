    NEWBANK EVAL


; see https://www.chessprogramming.org/Simplified_Evaluation_Function


VALUE_P = 100
VALUE_N = 320
VALUE_B = 330
VALUE_R = 500
VALUE_Q = 900
VALUE_K = 20000


    MAC VEQU
VALUE_{1} = {2}
    ENDM

    MAC LOBYTE
    .byte <{2}
    ENDM

    MAC HIBYTE
    .byte >{2}
    ENDM


    MAC VALUETABLE
    {1} BLANK, 0
    {1} PAWN, 100 ; white
    {1} PAWN, 100 ; black
    {1} KNIGHT, 320
    {1} BISHOP, 330
    {1} ROOK, 500
    {1} QUEEN, 900
    {1} KING, 20000
    ENDM


    VALUETABLE VEQU

    DEF PieceValueLO
        VALUETABLE LOBYTE

    DEF PieceValueHI
        VALUETABLE HIBYTE


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

    ; Adjust the material score based on the piece
    ; y = piece type

                    clc
                    lda PieceValueLO,y
                    adc Evaluation
                    sta Evaluation
                    lda PieceValueHI,y
                    adc Evaluation+1
                    sta Evaluation+1
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPiecePositionValue
    SUBROUTINE

            VAR __pval, 2


    ; adds value of square piece is on to the evaluation
    ; note to do the subtraction as -( -x + val) == x - val
    
    ; y = square
    ; a = piece type (+flags)



                    cmp #128                        ; black = CS
                    and #PIECE_MASK
                    tax

    IF ASSERTS
.kill   beq .kill ; can't have a 0-piece. something is wrong.
    ENDIF

    ; black pieces flip rows so we can use the same eval tables

                    tya
                    bcc .white
                    lda FlipSquareIndex,y
                    clc                    
.white
                    adc PosValVecLO,x
                    sta __pval
                    lda PosValVecHI,x
                    adc #0
                    sta __pval+1

                    ldy #0
                    lda (__pval),y
                    bpl .pos
                    dey                             ; odd double-usage of y - now it's hi byte
.pos

                    ;clc
                    adc Evaluation
                    sta Evaluation
                    tya
                    adc Evaluation+1
                    sta Evaluation+1
                    rts


;---------------------------------------------------------------------------------------------------

    ALLOCATE FlipSquareIndex, 100

    .byte 0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0

.SQBASE SET 90
    REPEAT 8
    .byte 0,0
.SQX SET 2
    REPEAT 8
    .byte (.SQBASE+.SQX)
.SQX SET .SQX + 1
    REPEND
.SQBASE SET .SQBASE - 10
    REPEND


;---------------------------------------------------------------------------------------------------
; Vectors to the position value tables for each piece

    MAC POSVAL
    .byte 0
    .byte {1}(PositionalValue_PAWN - 22)
    .byte {1}(PositionalValue_PAWN - 22)
    .byte {1}(PositionalValue_KNIGHT - 22)
    .byte {1}(PositionalValue_BISHOP - 22)
    .byte {1}(PositionalValue_ROOK - 22)
    .byte {1}(PositionalValue_QUEEN - 22)
    .byte {1}(PositionalValue_KING_MIDGAME - 22)
    ENDM

    ALLOCATE PosValVecLO, 8
    POSVAL <
    ALLOCATE PosValVecHI, 8
    POSVAL >


;---------------------------------------------------------------------------------------------------

PositionalValue_PAWN

    .byte            0,  0,  0,  0,  0,  0,  0,  0 ; 20-29
    .byte 0,0,       5, 10, 10,-20,-20, 10, 10,  5 ; 30-
    .byte 0,0,       5, -5,-10,  0,  0,-10, -5,  5 ; 40-
    .byte 0,0,       0,  0,  0, 20, 20,  0,  0,  0 ; 50-
    .byte 0,0,       5,  5, 10, 25, 25, 10,  5,  5 ; 60-
    .byte 0,0,      10, 10, 20, 30, 30, 20, 10, 10 ; 70-
    .byte 0,0,      50, 50, 50, 50, 50, 50, 50, 50 ; 80-
    .byte 0,0,       0,  0,  0,  0,  0,  0,  0,  0 ; 90-

PositionalValue_PAWN_BLACK

    .byte            0,  0,  0,  0,  0,  0,  0,  0 ; 20-29
    .byte 0,0,      50, 50, 50, 50, 50, 50, 50, 50 ; 30-
    .byte 0,0,      10, 10, 20, 30, 30, 20, 10, 10 ; 40-
    .byte 0,0,       5,  5, 10, 25, 25, 10,  5,  5 ; 50-
    .byte 0,0,       0,  0,  0, 20, 20,  0,  0,  0 ; 60-
    .byte 0,0,       5, -5,-10,  0,  0,-10, -5,  5 ; 70-
    .byte 0,0,       5, 10, 10,-20,-20, 10, 10,  5 ; 80-
    .byte 0,0,       0,  0,  0,  0,  0,  0,  0,  0 ; 90-

;---------------------------------------------------------------------------------------------------

PositionalValue_KNIGHT

    .byte            -50,-40,-30,-30,-30,-30,-40,-50
    .byte 0,0,       -40,-20,  0,  5,  5,  0,-20,-40
    .byte 0,0,       -30,  5, 10, 15, 15, 10,  5,-30
    .byte 0,0,       -30,  0, 15, 20, 20, 15,  0,-30
    .byte 0,0,       -30,  5, 15, 20, 20, 15,  5,-30
    .byte 0,0,       -30,  0, 10, 15, 15, 10,  0,-30
    .byte 0,0,       -40,-20,  0,  0,  0,  0,-20,-40
    .byte 0,0,       -50,-40,-30,-30,-30,-30,-40,-50


;---------------------------------------------------------------------------------------------------

PositionalValue_BISHOP

    .byte            -20,-10,-10,-10,-10,-10,-10,-20
    .byte 0,0,       -10,  5,  0,  0,  0,  0,  5,-10
    .byte 0,0,       -10, 10, 10, 10, 10, 10, 10,-10
    .byte 0,0,       -10,  0, 10, 10, 10, 10,  0,-10
    .byte 0,0,       -10,  5,  5, 10, 10,  5,  5,-10
    .byte 0,0,       -10,  0,  5, 10, 10,  5,  0,-10
    .byte 0,0,       -10,  0,  0,  0,  0,  0,  0,-10
    .byte 0,0,       -20,-10,-10,-10,-10,-10,-10,-20


;---------------------------------------------------------------------------------------------------

PositionalValue_ROOK

    .byte              0,  0,  0,  5,  5,  0,  0,  0
    .byte 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .byte 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .byte 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .byte 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .byte 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .byte 0,0,         5, 10, 10, 10, 10, 10, 10,  5
    .byte 0,0,         0,  0,  0,  0,  0,  0,  0,  0


;---------------------------------------------------------------------------------------------------

PositionalValue_QUEEN

    .byte              -20,-10,-10, -5, -5,-10,-10,-20
    .byte 0,0,         -10,  0,  5,  0,  0,  0,  0,-10
    .byte 0,0,         -10,  5,  5,  5,  5,  5,  0,-10
    .byte 0,0,           0,  0,  5,  5,  5,  5,  0, -5
    .byte 0,0,          -5,  0,  5,  5,  5,  5,  0, -5
    .byte 0,0,         -10,  0,  5,  5,  5,  5,  0,-10
    .byte 0,0,         -10,  0,  0,  0,  0,  0,  0,-10
    .byte 0,0,         -20,-10,-10, -5, -5,-10,-10,-20


;---------------------------------------------------------------------------------------------------

PositionalValue_KING_MIDGAME

    .byte               20, 30, 10,  0,  0, 10, 30, 20
    .byte 0,0,          20, 20,  0,  0,  0,  0, 20, 20
    .byte 0,0,         -10,-20,-20,-20,-20,-20,-20,-10
    .byte 0,0,         -20,-30,-30,-40,-40,-30,-30,-20
    .byte 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .byte 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .byte 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .byte 0,0,         -30,-40,-40,-50,-50,-40,-40,-30


;---------------------------------------------------------------------------------------------------

PositionalValue_KING_ENDGAME

    .byte               -50,-30,-30,-30,-30,-30,-30,-50
    .byte 0,0,          -30,-30,  0,  0,  0,  0,-30,-30
    .byte 0,0,          -30,-10, 20, 30, 30, 20,-10,-30
    .byte 0,0,          -30,-10, 30, 40, 40, 30,-10,-30
    .byte 0,0,          -30,-10, 30, 40, 40, 30,-10,-30
    .byte 0,0,          -30,-10, 20, 30, 30, 20,-10,-30
    .byte 0,0,          -30,-20,-10,  0,  0,-10,-20,-30
    .byte 0,0,          -50,-40,-30,-20,-20,-30,-40,-50


    CHECK_BANK_SIZE "BANK_EVAL"

;---------------------------------------------------------------------------------------------------


    MAC NEGATE ;{1}

        sec
        lda #0
        sbc {1}
        sta {1}
        lda #0
        sbc {1}+1
        sta {1}+1

    ENDM


    MAC RETURN ;{1}

        lda {1}
        sta return
        lda {1}+1
        sta return+1

        rts
    ENDM

    MAC IFNOTGE ; {1},{2}, {3}

    ; branch if NOT >=
    
        sec
        lda {1}
        sbc {2}
        lda {1}+1
        sbc {2}+1
        bcc {3}
    ENDM

    MAC IFNOTLT ; {1}, {2}, {3}

    ; branch if NOT <

        clc ;!!
        lda {1}
        sbc {2}
        lda {1}+1
        sbc {2}+1
        bcs {3}
    ENDM





    MAC EQUALS ; {1}, {2}

        lda {2}
        sta {1}
        lda {2}+1
        sta {1}+1

    ENDM

    ;DEF quiesce
    SUBROUTINE



#if 0
        ; alpha, beta

;def quiesce( alpha, beta ):
;    stand_pat = evaluate_board()

;--------------------------------------
;    if( stand_pat >= beta ):
;        return beta

;--------------------------------------
;    if( alpha < stand_pat ):
;        alpha = stand_pat

;--------------------------------------
; TODO
;    for move in board.legal_moves:
;    {
;        if board.is_capture(move):
;            make_move(move)

;--------------------------------------
;            score = -quiesce( -beta, -alpha )

                    NEGATE beta
                    NEGATE alpha

                    jsr quiesce

                    EQUALS score, return
                    NEGATE score

                    NEGATE beta
                    NEGATE alpha

; TODO:
;            unmake_move()

;--------------------------------------
;            if( score >= beta ):
;                return beta

                    IFNOTGE score, beta, cont24
                    RETURN beta

cont24
;            if( score > alpha ):
;                alpha = score

                    IFNOTLT alpha, score, cont25
                    EQUALS alpha, score
cont25
    ; } end of for ;oop

;    return alpha
                    RETURN alpha



#endif



#if 0

def quiesce( alpha, beta ):
    stand_pat = evaluate_board()
    if( stand_pat >= beta ):
        return beta
    if( alpha < stand_pat ):
        alpha = stand_pat

    for move in board.legal_moves:
        if board.is_capture(move):
            make_move(move)
            score = -quiesce( -beta, -alpha )
            unmake_move()

            if( score >= beta ):
                return beta
            if( score > alpha ):
                alpha = score
    return alpha

    DEF alphaBeta
    ; pass alpha[2], beta[2], depthleft



;def alphabeta( alpha, beta, depthleft ):
;    bestscore = -9999
;    if( depthleft == 0 ):
;        return quiesce( alpha, beta )
;    for move in board.legal_moves:
;        make_move(move)
;        score = -alphabeta( -beta, -alpha, depthleft - 1 )
;        unmake_move()
;        if( score >= beta ):
;            return score
;        if( score > bestscore ):
;            bestscore = score
;        if( score > alpha ):
;            alpha = score
;    return bestscore


        VAR __bestScore, 2
        VAR __score, 2

                    lda #<-infinity
                    sta __bestScore
                    lda #>-infinity
                    sta __bestScore+1

                    lda depthLeft
                    bne .moreDepth

                    jsr quiesce         ; --> return
                    rts


.moreDepth

; for move
; make move


;        score = -alphabeta( -beta, -alpha, depthleft - 1 )

                    lda alpha
                    pha
                    lda alpha+1
                    pha
                    lda beta
                    pha
                    lda beta+1
                    pha


                    sec
                    lda #0
                    sbc alpha
                    pha
                    lda #0
                    sbc alpha+1
                    pha

                    sec
                    lda #0
                    sbc beta
                    sta alpha
                    lda #0
                    sbc beta+1
                    sta alpha+1                     ; --> -beta

                    pla
                    sta beta+1
                    pla
                    sta beta                        ; --> -alpha

                    lda depthLeft
                    pha
                    dec depthLeft

                    lda __bestScore
                    pha
                    lda __bestScore+1
                    pha

                    jsr alphaBeta

                    sec
                    lda #0
                    sbc result
                    sta __score
                    lda #0
                    sbc result+1
                    sta __score+1

                    pla
                    sta __bestScore+1
                    pla
                    sta __bestScore

                    pla
                    sta depthLeft

                    pla
                    sta beta+1
                    pla
                    sta beta
                    pla
                    sta alpha+1
                    pla
                    sta alpha


        ; TODO: unmake move


;        if( score >= beta ):
;            return score

                    sec
                    lda __score
                    sbc beta
                    lda __score+1
                    sbc beta+1
                    bcc .notScoreGteBeta

                    lda __score
                    sta result
                    lda __score+1
                    sta result+1
                    rts

.notScoreGteBeta

;        if( score > bestscore ):
;            bestscore = score

                    clc                     ; !!
                    lda __bestScore
                    sbc __score
                    lda __bestScore+1
                    sbc __score+1
                    bcs .notScoreGtBestScore

                    lda __score
                    sta __bestScore
                    lda __score+1
                    sta __bestScore+1

.notScoreGtBestScore

;        if( score > alpha ):
;            alpha = score

                    clc                     ; !!
                    lda alpha
                    sbc __score
                    lda alpha+1
                    sbc __score+1
                    bcs .notScoreGtAlpha

                    lda __score
                    sta alpha
                    lda __score+1
                    sta alpha+1

    ; TODO end move loop here

;    return bestscore

                    lda __bestScore
                    sta return
                    lda __bestScore+1
                    sta return+1
                    rts






import chess.polyglot

def selectmove(depth):
    try:
        move = chess.polyglot.MemoryMappedReader("bookfish.bin").weighted_choice(board).move()
        movehistory.append(move)
        return move
    except:



;        bestMove = chess.Move.null()
;        bestValue = -99999
;        alpha = -100000
;        beta = 100000



                    lda #-1
                    sta bestMove

                    lda #<(-infinity)
                    sta alpha
                    lda #>(-infinity)
                    sta alpha+1

                    lda #<infinity
                    sta beta
                    lda #>infinity
                    sta beta+1

                    lda #<(-(infinity-1))
                    sta bestValue
                    lda #<(-(infinity-1))
                    sta bestValue+1

;        for move in board.legal_moves:
;            make_move(move)

;            boardValue = -alphabeta(-beta, -alpha, depth-1)

                    lda alpha
                    pha
                    lda alpha+1
                    pha
                    lda beta
                    pha
                    lda beta+1
                    pha
                    lda depth
                    pha

                    dec depth

                    sec
                    lda #0
                    sbc beta



            if boardValue > bestValue:
                bestValue = boardValue;
                bestMove = move
            if( boardValue > alpha ):
                alpha = boardValue
            unmake_move()
        movehistory.append(bestMove)
        return bestMove


#endif





; EOF
