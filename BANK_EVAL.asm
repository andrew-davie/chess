    NEWBANK EVAL


; see https://www.chessprogramming.org/Simplified_Evaluation_Function


;VALUE_P = 100
;VALUE_N = 325
;VALUE_B = 350
;VALUE_R = 575
;VALUE_Q = 900
;VALUE_K = 20000


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
    {1} BLANK,    0
    {1} PAWN,   100 ; white
    {1} PAWN,   100 ; black
    {1} KNIGHT, 320
    {1} BISHOP, 330
    {1} ROOK,   575
    {1} QUEEN,  900
    {1} KING, 10000
    ENDM


    VALUETABLE VEQU

    DEF PieceValueLO
        VALUETABLE LOBYTE

    DEF PieceValueHI
        VALUETABLE HIBYTE


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

        REFER AdjustMaterialPositionalValue
        REFER DeletePiece
        REFER InitialisePieceSquares
        VEND AddPieceMaterialValue

    ; Adjust the material score based on the piece
    ; a = piece type + flags

                    and #PIECE_MASK
                    tay

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

        REFER AdjustMaterialPositionalValue
        REFER DeletePiece
        REFER negamax
        REFER quiesce
        VAR __valPtr, 2
        VEND AddPiecePositionValue


    ; adds value of square piece is on to the evaluation
    ; note to do the subtraction as -( -x + val) == x - val
    
    ; y = square
    ; a = piece type (+flags)



                    cmp #128                        ; black = CS
                    and #PIECE_MASK
                    tax

    ; black pieces flip rows so we can use the same eval tables

                    tya
                    bcc .white
                    lda FlipSquareIndex,y
                    ;clc                    
.white
                    adc PosValVecLO,x
                    sta __valPtr
                    lda PosValVecHI,x
                    adc #0
                    sta __valPtr+1

                    ldy #0
                    lda (__valPtr),y

                    ;clc
                    adc Evaluation
                    sta Evaluation
                    bcc .noH
                    inc Evaluation+1
.noH                rts



;---------------------------------------------------------------------------------------------------

    ALLOCATE FlipSquareIndex, 100

    .byte 0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0

.SQBASE SET 90-1
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

BZ = 50

    MAC PVAL ;{ 10 entries }
        .byte BZ + {1}
        .byte BZ + {2}
        .byte BZ + {3}
        .byte BZ + {4}
        .byte BZ + {5}
        .byte BZ + {6}
        .byte BZ + {7}
        .byte BZ + {8}
        .byte BZ
        .byte BZ
    ENDM

;---------------------------------------------------------------------------------------------------

PositionalValue_PAWN

    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    PVAL   5,  10,   0, -20, -20,   0,  10,   5
    PVAL   5,  -5, -10,   0,   0, -10,  -5,   5
    PVAL   0,   0,   0,  10,  10,   0,   0,   0
    PVAL   5,  15,  20,  20,  20,  20,  15,   5
    PVAL  10,  20,  30,  40,  40,  30,  20,  10
    PVAL  50,  50,  60,  70,  70,  60,  50,  50
    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    
PositionalValue_PAWN_BLACK

    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    PVAL  50,  50,  60,  70,  70,  60,  60,  50
    PVAL  10,  20,  30,  40,  40,  30,  20,  10
    PVAL   5,  15,  10,  20,  20,  20,  15,   5
    PVAL   0,   0,   0,  10,  10,   0,   0,   0
    PVAL   5,  -5, -10,   0,   0, -10,  -5,   5
    PVAL   5,  10,   0, -20, -20,   0,  10,   5
    PVAL   0,   0,   0,   0,   0,   0,   0,   0

;---------------------------------------------------------------------------------------------------

PositionalValue_KNIGHT

    PVAL -50, -20, -30, -30, -30, -30, -20, -50
    PVAL -40, -20,   0,   5,   5,   0, -20, -40
    PVAL -30,   0,   0,  15,  15,   0,   0, -30
    PVAL -30,   0,  15,  60,  60,  15,   0, -30
    PVAL -30,   5,  15,  60,  60,  15,   5, -30
    PVAL -30,   0,  10,  15,  15,  10,   0, -30
    PVAL -40, -20,  30,   0,   0,  30, -20, -40
    PVAL -50, -40, -30, -30, -30, -30, -40, -50


;---------------------------------------------------------------------------------------------------

PositionalValue_BISHOP

    PVAL -20, -10, -10, -10, -10, -10, -10, -20
    PVAL -10,   5,   0,   0,   0,   0,   5, -10
    PVAL -10,  10,  10,  10,  10,  10,  10, -10
    PVAL -10,   0,  10,  20,  20,  10,   0, -10
    PVAL -10,   5,   5,  20,  20,   5,   5, -10
    PVAL -10,   0,   5,  10,  10,   5,   0, -10
    PVAL -10,   0,   0,   0,   0,   0,   0, -10
    PVAL -20, -10, -10, -10, -10, -10, -10, -20


;---------------------------------------------------------------------------------------------------

PositionalValue_ROOK

    PVAL   0,   0,  10,  25,  25,  10,   0,   0
    PVAL  -5,   0,   0,   0,   0,   0,   0,  -5
    PVAL  -5,   0,   0,   0,   0,   0,   0,  -5
    PVAL  -5,   0,   0,   0,   0,   0,   0,  -5
    PVAL  -5,   0,   0,   0,   0,   0,   0,  -5
    PVAL  -5,   0,  10,  10,  10,  10,   0,  -5
    PVAL   5,  10,  30,  30,  30,  30,  10,   5
    PVAL   0,   0,   0,   0,   0,   0,   0,   0


;---------------------------------------------------------------------------------------------------

PositionalValue_QUEEN

    PVAL -20, -10, -10,  -5,  -5, -10, -10, -20
    PVAL -10,   0,   5,   0,   0,   0,   0, -10
    PVAL -10,   5,   5,   5,   5,   5,   0, -10
    PVAL -10,   0,   5,  25,  25,  25,   0, -10
    PVAL  -5,   0,  15,  55,  55,  55,   0,  -5
    PVAL -10,   0,  25,  75,  75,  75,   0, -10
    PVAL -10,   0,   0,   0,   0,   0,   0, -10
    PVAL -20, -10, -10,  -5,  -5, -10, -10, -20


;---------------------------------------------------------------------------------------------------

PositionalValue_KING_MIDGAME

    PVAL  20,  30,  10,   0,   0,  10,  30,  20
    PVAL  20,  20,   0,   0,   0,   0,  20,  20
    PVAL -10, -20, -20, -20, -20, -20, -20, -10
    PVAL -20, -30, -30, -40, -40, -30, -30, -20
    PVAL -30, -40, -40, -50, -50, -40, -40, -30
    PVAL -30, -40, -40, -50, -50, -40, -40, -30
    PVAL -30, -40, -40, -50, -50, -40, -40, -30
    PVAL -30, -40, -40, -50, -50, -40, -40, -30


;---------------------------------------------------------------------------------------------------

PositionalValue_KING_ENDGAME

    PVAL -50, -30, -30, -30, -30, -30, -30, -50
    PVAL -30, -30,   0,   0,   0,   0, -30, -30
    PVAL -30, -10,  20,  30,  30,  20, -10, -30
    PVAL -30, -10,  30,  40,  40,  30, -10, -30
    PVAL -30, -10,  30,  40,  40,  30, -10, -30
    PVAL -30, -10,  20,  30,  30,  20, -10, -30
    PVAL -30, -20, -10,   0,   0, -10, -20, -30
    PVAL -50, -40, -30, -20,- 20, -30, -40, -50


    CHECK_BANK_SIZE "BANK_EVAL"

;---------------------------------------------------------------------------------------------------
; EOF
