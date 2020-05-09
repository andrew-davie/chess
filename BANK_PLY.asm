; Copyright (C)2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1
    NEWBANK BANK_PLY                   ; ROM SHADOW

    
;---------------------------------------------------------------------------------------------------

    DEF NewPlyInitialise
    SUBROUTINE

        REFER GenerateAllMoves
        REFER negaMax
        VEND NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty
    ; x must be preserved

    ; note that 'alpha' and 'beta' are set externally!!

                    lda #-1
                    sta@PLY moveIndex           ; no valid moves
                    sta@PLY bestMove

                    lda enPassantPawn               ; flag/square from last actual move made
                    sta@PLY enPassantSquare         ; used for backtracking, to reset the flag


    ; The value of the material (signed, 16-bit) is restored to the saved value at the reversion
    ; of a move. It's quicker to restore than to re-sum. So we save the current evaluation at the
    ; start of each new ply.

                    lda Evaluation
                    sta@PLY savedEvaluation
                    lda Evaluation+1
                    sta@PLY savedEvaluation+1

                    rts



;---------------------------------------------------------------------------------------------------

    MAC XCHG ;{name}
        lda@PLY {1},x
        sta __xchg
        lda@PLY {1},y
        sta@PLY {1},x
        lda __xchg
        sta@PLY {1},y
    ENDM


    DEF Sort
    SUBROUTINE

        REFER GenerateAllMoves
        VAR __xchg, 1
        VEND Sort

                    lda __quiesceCapOnly
                    bmi .exit                       ; only caps present so already sorted!

                    ldx@PLY moveIndex
                    ldy@PLY moveIndex
.next               dey
                    bmi .exit

                    lda@PLY MoveCapture,y
                    beq .next

                    XCHG MoveFrom
                    XCHG MoveTo
                    XCHG MovePiece
                    XCHG MoveCapture

                    dex
                    bpl .next

.exit




    ; Scan for capture of king

                    ldx@PLY moveIndex

.scanCheck          lda@PLY MoveCapture,x
                    beq .check                      ; since they're sorted with captures "first" we can exit
                    and #PIECE_MASK
                    cmp #KING
                    beq .check
                    dex
                    bpl .scanCheck

                    lda #0
.check              sta flagCheck
                    rts


;---------------------------------------------------------------------------------------------------
; QUIESCE!

;int Quiesce( int alpha, int beta ) {
;    int stand_pat = Evaluate();
;    if( stand_pat >= beta )
;        return beta;
;    if( alpha < stand_pat )
;        alpha = stand_pat;

;    until( every_capture_has_been_examined )  {
;        MakeCapture();
;        score = -Quiesce( -beta, -alpha );
;        TakeBackMove();

;        if( score >= beta )
;            return beta;
;        if( score > alpha )
;           alpha = score;
;    }
;    return alpha;
;}


    DEF quiesce
    SUBROUTINE

    ; pass...
    ; x = depthleft
    ; SET_BANK_RAM      --> current ply
    ; __alpha[2] = param alpha
    ; __beta[2] = param beta


        COMMON_VARS_ALPHABETA
        REFER selectmove
        REFER negaMax
        VEND quiesce

                    lda currentPly
                    cmp #RAMBANK_PLY + MAX_PLY_DEPTH_BANK -1
                    bcs .retBeta

    ; The 'thinkbar' pattern...

                    lda #0
                    ldy INPT4
                    bmi .doThink
    
                    lda __thinkbar
                    asl
                    asl
                    asl
                    asl
                    ora #2
                    sta COLUPF

                    inc __thinkbar
                    lda __thinkbar
                    and #15
                    tay
                    lda SynapsePattern2,y

.doThink            sta PF1
                    sta PF2

    ; ^

                    lda __beta
                    sta@PLY beta
                    lda __beta+1
                    sta@PLY beta+1

                    lda __alpha
                    sta@PLY alpha
                    lda __alpha+1
                    sta@PLY alpha+1


    ;    int stand_pat = Evaluate();
    ;    if( stand_pat >= beta )
    ;        return beta;

                    sec
                    lda Evaluation
                    sbc@PLY beta
                    lda Evaluation+1
                    sbc@PLY beta+1
                    bvc .spat0
                    eor #$80
.spat0              bmi .norb ;pl .retBeta                    ; branch if stand_pat >= beta

.retBeta            lda beta
                    sta __negaMax
                    lda beta+1
                    sta __negaMax+1

.abort              rts                    

.norb


    ;    if( alpha < stand_pat )
    ;        alpha = stand_pat;

                    sec
                    lda alpha
                    sbc Evaluation
                    lda alpha+1
                    sbc Evaluation+1
                    bvc .spat1
                    eor #$80
.spat1              bpl .alpha                      ; branch if alpha >= stand_pat

    ; alpha < stand_pat

                    lda Evaluation
                    sta@PLY alpha
                    lda Evaluation+1
                    sta@PLY alpha+1

.alpha
                    jsr GenerateAllMoves
                    lda flagCheck
                    bne .abort                      ; pure abort

                    ldx@PLY moveIndex
                    bmi .exit
                    
.forChild           stx@PLY movePtr

    ; The movelist has captures ONLY (ref: __quiesceCapOnly != 0)

                    jsr MakeMove

                    sec
                    lda #0
                    sbc@PLY beta
                    sta __alpha
                    lda #0
                    sbc@PLY beta+1
                    sta __alpha+1

                    sec
                    lda #0
                    sbc@PLY alpha
                    sta __beta
                    lda #0
                    sbc@PLY alpha+1
                    sta __beta+1

                    inc currentPly
                    lda currentPly
                    sta SET_BANK_RAM                ; self-switch

                    jsr quiesce

                    dec currentPly
                    ;lda currentPly
                    ;sta SET_BANK_RAM

                    jsr unmakeMove;@0

                    lda flagCheck                   ; don't consider moves which leave us in check
                    bne .inCheck
                    
                    sec
                    ;lda #0                         ; already 0
                    sbc __negaMax
                    sta __negaMax
                    lda #0
                    sbc __negaMax+1
                    sta __negaMax+1                 ; -negaMax(...)



;        if( score >= beta )
;            return beta;


                    sec
                    lda __negaMax
                    sbc@PLY beta
                    lda __negaMax+1
                    sbc@PLY beta+1
                    bvc .lab0
                    eor #$80
.lab0               bmi .nrb2 ; .retBeta                    ; branch if score >= beta
                    jmp .retBeta
.nrb2

;        if( score > alpha )
;           alpha = score;
;    }

                    sec
                    lda@PLY alpha
                    sbc __negaMax
                    lda@PLY alpha+1
                    sbc __negaMax+1
                    bvc .lab2
                    eor #$80
.lab2               bpl .nextMove                   ; alpha >= score

    ; score > alpha

                    lda __negaMax
                    sta@PLY alpha
                    lda __negaMax+1
                    sta@PLY alpha+1

.nextMove           ldx@PLY movePtr
                    dex
                    bpl .forChild

;    return alpha;

.exit
                    lda@PLY alpha
                    sta __negaMax
                    lda@PLY alpha+1
                    sta __negaMax+1
                    rts

.inCheck            lda #0
                    sta flagCheck
                    beq .nextMove



SynapsePattern2

    .byte %11000001
    .byte %01100000
    .byte %00110000
    .byte %00011000
    .byte %00001100
    .byte %00000110
    .byte %10000011
    .byte %11000001

    .byte %10000011
    .byte %00000110
    .byte %00001100
    .byte %00011000
    .byte %00110000
    .byte %01100000
    .byte %11000001
    .byte %10000011


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_PLY"

;---------------------------------------------------------------------------------------------------
; EOF
