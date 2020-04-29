    NEWRAMBANK BANK_EVAL
    NEWBANK EVAL


; see https://www.chessprogramming.org/Simplified_Evaluation_Function



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
    {1} BISHOP, 375
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

    DEF EnPassantRemovePiece
    SUBROUTINE

        REFER MakeMove
    IF ENPASSANT_ENABLED
        REFER EnPassantCheck
    ENDIF
        VAR __y, 1
        VAR __col, 1
        VEND EnPassantRemovePiece


    ; Based on piece square, adjust material and position value with piece deleted
    ; y = piece square

                    sty __y

                    jsr GetBoard
                    sta __col
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; adding for opponent = taking

                    lda currentPly
                    sta SET_BANK_RAM
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

        REFER AdjustMaterialPositionalValue
        REFER InitialisePieceSquares
        REFER EnPassantRemovePiece
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
        REFER negaMax
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



    DEF IncVal
    SUBROUTINE

        ldx #99
.higher  clc
        lda@RAM PositionalValue_PAWN_BLACK,x
        adc #10
        cmp #$7F
        bcc .norm
        lda #$7f
.norm   sta@RAM PositionalValue_PAWN_BLACK,x
        dex
        bpl .higher
        rts

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
    PVAL  15,  10,   0, -20, -20,   0,  10,  15
    PVAL   5,  -5, -10,   0,   0, -10,  -5,   5
    PVAL   0,   0,   0,  10,  40,   0,   0,   0
    PVAL  15,  15,  20,  20,  50,  20,  15,  15
    PVAL  30,  30,  40,  50,  50,  40,  30,  30
    PVAL  40,  50,  60,  70,  70,  60,  50,  40
    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    
PositionalValue_PAWN_BLACK

    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    PVAL  40,  50,  60,  70,  70,  60,  60,  40
    PVAL  30,  30,  40,  50,  50,  40,  30,  30
    PVAL  15,  15,  10,  40,  40,  20,  15,  15
    PVAL   0,   0,   0,  30,  30,   0,   0,   0
    PVAL   5,  -5, -10,   0,   0, -10,  -5,   5
    PVAL  15,  10,   0, -20, -20,   0,  10,  15
    PVAL   0,   0,   0,   0,   0,   0,   0,   0

;---------------------------------------------------------------------------------------------------

PositionalValue_KNIGHT

    PVAL -50, -40, -30, -30, -30, -30, -40, -50
    PVAL -40, -20,   0,   5,   5,   0, -20, -40
    PVAL -30,   0,  20,  15,  15,  20,   0, -30
    PVAL -30,   0,  15,  30,  30,  15,   0, -30
    PVAL -30,   5,  15,  30,  30,  15,   5, -30
    PVAL -30,   0,  10,  15,  15,  10,   0, -30
    PVAL -40, -20,  30,   0,   0,  30, -20, -40
    PVAL -50, -20, -30, -30, -30, -30, -20, -50


;---------------------------------------------------------------------------------------------------

PositionalValue_BISHOP

    PVAL -20, -10, -50, -10, -10, -50, -10, -20
    PVAL -10,   5,   0,   0,   0,   0,   5, -10
    PVAL -10,  10,  10,  10,  10,  10,  10, -10
    PVAL -10,   0,  10,  20,  20,  10,   0, -10
    PVAL -10,   5,   5,  20,  20,   5,   5, -10
    PVAL -10,   0,   5,  10,  10,   5,   0, -10
    PVAL -10,   0,   0,   0,   0,   0,   0, -10
    PVAL -20, -10, -10, -10, -10, -10, -10, -20


;---------------------------------------------------------------------------------------------------

PositionalValue_ROOK

    PVAL -120, -10,  10,  25,  25,  10, -10, -200
    PVAL  -75,   0,   0,   0,   0,   0,   0,  -200
    PVAL  -75,   0,   0,   0,   0,   0,   0,  -150
    PVAL  -50,   0,   0,   0,   0,   0,   0,  -100
    PVAL  -5,   0,   0,   0,   0,   0,   0,  -50
    PVAL  -5,   0,  30,  30,  30,  30,   0,  -5
    PVAL   5,  10,  50,  50,  50,  50,  10,   5
    PVAL   0,   0,   0,   0,   0,   0,   0,   0


;---------------------------------------------------------------------------------------------------

PositionalValue_QUEEN

    PVAL -20, -10,  -5,  -5,  -5, -10, -10, -20
    PVAL -10,   0,   5,   0,   0,   0,   0, -10
    PVAL -10,   5,   5,   5,   5,  25,   0, -10
    PVAL -10,   0,   5,  25,  25,  25,   0, -10
    PVAL  -5,   0,  15,  55,  55,  55,   0,  -5
    PVAL -10,   0,  25,  75,  75,  75,   0, -10
    PVAL -10,   0,   0,   0,   0,   0,   0, -10
    PVAL -20, -10, -10,  -5,  -5, -10, -10, -20


;---------------------------------------------------------------------------------------------------

PositionalValue_KING_MIDGAME

    PVAL   0,   0,  30, -20,   0,  10,  40,  10
    PVAL  20,  20,   0, -10, -10,   0,  20,  20
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
