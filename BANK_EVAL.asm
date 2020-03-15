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
    ; to REMOVE a piece, negate the piece colour!
    ; y = piece type
    ; carry C = white, S = black

        VAR __temp2,2

                    bcs .black


                    lda PieceValueLO,y
                    adc Evaluation
                    sta Evaluation
                    lda PieceValueHI,y
                    adc Evaluation+1
                    sta Evaluation+1
                    rts

.black              lda Evaluation
                    sbc PieceValueLO,y
                    sta Evaluation
                    lda Evaluation+1
                    sbc PieceValueHI,y
                    sta Evaluation+1
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPiecePositionValue
    SUBROUTINE

        VAR __pval, 2

    ; y = square
    ; a = piece type (+flags)

                    cmp #128                        ; black = CS
                    and #PIECE_MASK
                    tax

                    lda PosValVecLO,x
                    sta __pval
                    lda PosValVecHI,x
                    sta __pval+1

                    bcs .black

                    tya
                    asl
                    tay                             ; 16 bit values

                    clc
                    lda Evaluation
                    adc (__pval),y
                    sta Evaluation
                    iny
                    lda Evaluation+1
                    adc (__pval),y
                    sta Evaluation+1
                    rts

.black

                    tya
                    tax
                    ldy FlipSquareIndex,x           ; flip the index so we can use the same tables

                    sec
                    lda Evaluation
                    sbc (__pval),y
                    sta Evaluation
                    iny
                    lda Evaluation+1
                    sbc (__pval),y
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
    .byte (.SQBASE+.SQX)*2
.SQX SET .SQX + 1
    REPEND
.SQBASE SET .SQBASE - 10
    REPEND


;---------------------------------------------------------------------------------------------------
; Vectors to the position value tables for each piece

    MAC POSVAL
    .byte 0
    .byte {1}PositionalValue_PAWN
    .byte {1}PositionalValue_PAWN
    .byte {1}PositionalValue_KNIGHT
    .byte {1}PositionalValue_BISHOP
    .byte {1}PositionalValue_ROOK
    .byte {1}PositionalValue_QUEEN
    .byte {1}PositionalValue_KING_MIDGAME
    ENDM

    ALLOCATE PosValVecLO, 8
    POSVAL <
    ALLOCATE PosValVecHI, 8
    POSVAL >


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_PAWN, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,       0,  0,  0,  0,  0,  0,  0,  0 ; 20-29
    .word 0,0,       5, 10, 10,-20,-20, 10, 10,  5 ; 30-
    .word 0,0,       5, -5,-10,  0,  0,-10, -5,  5 ; 40-
    .word 0,0,       0,  0,  0, 20, 20,  0,  0,  0 ; 50-
    .word 0,0,       5,  5, 10, 25, 25, 10,  5,  5 ; 60-
    .word 0,0,      10, 10, 20, 30, 30, 20, 10, 10 ; 70-
    .word 0,0,      50, 50, 50, 50, 50, 50, 50, 50 ; 80-
    .word 0,0,      0,  0,  0,  0,  0,  0,  0,  0  ; 90-


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_KNIGHT, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,       -50,-40,-30,-30,-30,-30,-40,-50
    .word 0,0,       -40,-20,  0,  5,  5,  0,-20,-40
    .word 0,0,       -30,  5, 10, 15, 15, 10,  5,-30
    .word 0,0,       -30,  0, 15, 20, 20, 15,  0,-30
    .word 0,0,       -30,  5, 15, 20, 20, 15,  5,-30
    .word 0,0,       -30,  0, 10, 15, 15, 10,  0,-30
    .word 0,0,       -40,-20,  0,  0,  0,  0,-20,-40
    .word 0,0,       -50,-40,-30,-30,-30,-30,-40,-50


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_BISHOP, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,       -20,-10,-10,-10,-10,-10,-10,-20
    .word 0,0,       -10,  5,  0,  0,  0,  0,  5,-10
    .word 0,0,       -10, 10, 10, 10, 10, 10, 10,-10
    .word 0,0,       -10,  0, 10, 10, 10, 10,  0,-10
    .word 0,0,       -10,  5,  5, 10, 10,  5,  5,-10
    .word 0,0,       -10,  0,  5, 10, 10,  5,  0,-10
    .word 0,0,       -10,  0,  0,  0,  0,  0,  0,-10
    .word 0,0,       -20,-10,-10,-10,-10,-10,-10,-20


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_ROOK, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,         0,  0,  0,  5,  5,  0,  0,  0
    .word 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .word 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .word 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .word 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .word 0,0,        -5,  0,  0,  0,  0,  0,  0, -5
    .word 0,0,         5, 10, 10, 10, 10, 10, 10,  5
    .word 0,0,         0,  0,  0,  0,  0,  0,  0,  0


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_QUEEN, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,         -20,-10,-10, -5, -5,-10,-10,-20
    .word 0,0,         -10,  0,  5,  0,  0,  0,  0,-10
    .word 0,0,         -10,  5,  5,  5,  5,  5,  0,-10
    .word 0,0,           0,  0,  5,  5,  5,  5,  0, -5
    .word 0,0,          -5,  0,  5,  5,  5,  5,  0, -5
    .word 0,0,         -10,  0,  5,  5,  5,  5,  0,-10
    .word 0,0,         -10,  0,  0,  0,  0,  0,  0,-10
    .word 0,0,         -20,-10,-10, -5, -5,-10,-10,-20


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_KING_MIDGAME, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,          20, 30, 10,  0,  0, 10, 30, 20
    .word 0,0,          20, 20,  0,  0,  0,  0, 20, 20
    .word 0,0,         -10,-20,-20,-20,-20,-20,-20,-10
    .word 0,0,         -20,-30,-30,-40,-40,-30,-30,-20
    .word 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .word 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .word 0,0,         -30,-40,-40,-50,-50,-40,-40,-30
    .word 0,0,         -30,-40,-40,-50,-50,-40,-40,-30


;---------------------------------------------------------------------------------------------------

    ALLOCATE PositionalValue_KING_ENDGAME, 200

    .word 0,0,0,0,0,0,0,0,0,0
    .word 0,0,0,0,0,0,0,0,0,0

    .word 0,0,          -50,-30,-30,-30,-30,-30,-30,-50
    .word 0,0,          -30,-30,  0,  0,  0,  0,-30,-30
    .word 0,0,          -30,-10, 20, 30, 30, 20,-10,-30
    .word 0,0,          -30,-10, 30, 40, 40, 30,-10,-30
    .word 0,0,          -30,-10, 30, 40, 40, 30,-10,-30
    .word 0,0,          -30,-10, 20, 30, 30, 20,-10,-30
    .word 0,0,          -30,-20,-10,  0,  0,-10,-20,-30
    .word 0,0,          -50,-40,-30,-20,-20,-30,-40,-50


;---------------------------------------------------------------------------------------------------


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

def alphabeta( alpha, beta, depthleft ):
    bestscore = -9999
    if( depthleft == 0 ):
        return quiesce( alpha, beta )
    for move in board.legal_moves:
        make_move(move)
        score = -alphabeta( -beta, -alpha, depthleft - 1 )
        unmake_move()
        if( score >= beta ):
            return score
        if( score > bestscore ):
            bestscore = score
        if( score > alpha ):
            alpha = score
    return bestscore

import chess.polyglot

def selectmove(depth):
    try:
        move = chess.polyglot.MemoryMappedReader("bookfish.bin").weighted_choice(board).move()
        movehistory.append(move)
        return move
    except:
        bestMove = chess.Move.null()
        bestValue = -99999
        alpha = -100000
        beta = 100000
        for move in board.legal_moves:
            make_move(move)
            boardValue = -alphabeta(-beta, -alpha, depth-1)
            if boardValue > bestValue:
                bestValue = boardValue;
                bestMove = move
            if( boardValue > alpha ):
                alpha = boardValue
            unmake_move()
        movehistory.append(bestMove)
        return bestMove


def evaluate_board():

    if board.is_checkmate():
        if board.turn:
            return -9999
        else:
            return 9999
    if board.is_stalemate():
        return 0
    if board.is_insufficient_material():
        return 0

    eval = boardvalue
    if board.turn:
        return eval
    else:
        return -eval



piecetypes = [chess.PAWN, chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN, chess.KING ]
tables = [pawntable, knightstable, bishopstable, rookstable, queenstable, kingstable]
piecevalues = [100,320,330,500,900]

def update_eval(mov, side):
    global boardvalue

    #update piecequares
    movingpiece = board.piece_type_at(mov.from_square)
    if side:
        boardvalue = boardvalue - tables[movingpiece - 1][mov.from_square]
        #update castling
        if (mov.from_square == chess.E1) and (mov.to_square == chess.G1):
            boardvalue = boardvalue - rookstable[chess.H1]
            boardvalue = boardvalue + rookstable[chess.F1]
        elif (mov.from_square == chess.E1) and (mov.to_square == chess.C1):
            boardvalue = boardvalue - rookstable[chess.A1]
            boardvalue = boardvalue + rookstable[chess.D1]
    else:
        boardvalue = boardvalue + tables[movingpiece - 1][mov.from_square]
        #update castling
        if (mov.from_square == chess.E8) and (mov.to_square == chess.G8):
            boardvalue = boardvalue + rookstable[chess.H8]
            boardvalue = boardvalue - rookstable[chess.F8]
        elif (mov.from_square == chess.E8) and (mov.to_square == chess.C8):
            boardvalue = boardvalue + rookstable[chess.A8]
            boardvalue = boardvalue - rookstable[chess.D8]

    if side:
        boardvalue = boardvalue + tables[movingpiece - 1][mov.to_square]
    else:
        boardvalue = boardvalue - tables[movingpiece - 1][mov.to_square]


    #update material
    if mov.drop != None:
        if side:
            boardvalue = boardvalue + piecevalues[mov.drop-1]
        else:
            boardvalue = boardvalue - piecevalues[mov.drop-1]

    #update promotion
    if mov.promotion != None:
        if side:
            boardvalue = boardvalue + piecevalues[mov.promotion-1] - piecevalues[movingpiece-1]
            boardvalue = boardvalue - tables[movingpiece - 1][mov.to_square] \
                + tables[mov.promotion - 1][mov.to_square]
        else:
            boardvalue = boardvalue - piecevalues[mov.promotion-1] + piecevalues[movingpiece-1]
            boardvalue = boardvalue + tables[movingpiece - 1][mov.to_square] \
                - tables[mov.promotion - 1][mov.to_square]


    return mov

def make_move(mov):
    update_eval(mov, board.turn)
    board.push(mov)

    return mov

def unmake_move():
    mov = board.pop()
    update_eval(mov, not board.turn)

    return mov

#endif


    CHECK_BANK_SIZE "BANK_EVAL"



; EOF
