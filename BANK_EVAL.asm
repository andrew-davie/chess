    
    SLOT 3


    NEWRAMBANK BANK_EVAL
    NEWBANK EVAL


; see https://www.chessprogramming.org/Simplified_Evaluation_Function



;---------------------------------------------------------------------------------------------------
; Vectors to the position value tables for each piece

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
    .byte {1}(PositionalValue_KING_ENDGAME - 22)
    ENDM

    ALLOCATE PosValVecLO, 8
    POSVAL <
    ALLOCATE PosValVecHI, 8
    POSVAL >


    MAC EVAL8
    IF ({1} > 127) || ({1} < -128)
        ECHO "Erroneous position value", {1}
        ERR
    ENDIF
    .byte {1}
    ENDM


    MAC PVAL ;{ 10 entries }
        EVAL8 {1}
        EVAL8 {2}
        EVAL8 {3}
        EVAL8 {4}
        EVAL8 {5}
        EVAL8 {6}
        EVAL8 {7}
        EVAL8 {8}
        EVAL8 0
        EVAL8 0
    ENDM


    IF 0
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

BZ = 0

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
    ENDIF

;---------------------------------------------------------------------------------------------------

PositionalValue_PAWN

    PVAL   0,    0,   0,    0,   0,   0,   0,   0
    PVAL  15,  20,   0, -10, -10,   0,  20,  15
    PVAL   5,  -5,  20,   0,   0,  20,  -5,   5
    PVAL   5,   5,  10,  20,  40,  20,   5,   5
    PVAL  15,  15,  20,  40,  50,  20,  15,  15
    PVAL  60,  60,  80,  80,  80,  80,  60,  60
    PVAL  100, 100, 120, 120, 120, 120, 100, 100
    PVAL   0,   0,   0,   0,   0,   0,   0,   0
    
;---------------------------------------------------------------------------------------------------

PositionalValue_KNIGHT

    PVAL -50, -30, -30, -30, -30, -30, -22, -50
    PVAL -40, -20,   0,  -5,  -25,   0, -20, -40
    PVAL -30,   0,  18,  15,  15,  18,   0, -30
    PVAL -40,   0,  15,  30,  30,  15,   0, -40
    PVAL -40,   5,  15,  30,  30,  15,   5, -40
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

    PVAL   -25, -20,  10,  55,  55,  50, -20,  -25
    PVAL  -120,   0,   0,   0,   0,   0,   0, -128
    PVAL  -128,   0,   0,   0,   0,   0,   0, -100
    PVAL   -100,   0,   0,   0,   0,   0,   0, -100
    PVAL   -50,    0,   0,   0,   0,   0,   0,  -50
    PVAL   -5,    0,  30,  30,  30,  30,   0,   -5
    PVAL   55,   80,  90,  90,  90,  90,  80,    55
    PVAL    0,    0,   0,   0,   0,   0,   0,    0


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

    PVAL   0,   0,  40, -60, -30,   0,  50,  0
    PVAL   0,   0,  -80, -80, -70, -70,  0,  0
    PVAL -10, -20, -20, -20, -30, -20, -20, -10
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
