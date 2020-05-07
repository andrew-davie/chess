; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1 ; this code assembles for bank #1
    NEWBANK NEGAMAX

;---------------------------------------------------------------------------------------------------

;function negaMax(node, depth, α, β, color) is
;    if depth = 0 or node is a terminal node then
;        return color × the heuristic value of node

;    childNodes := generateMoves(node)
;    childNodes := orderMoves(childNodes)
;    value := −∞
;    foreach child in childNodes do
;        value := max(value, −negaMax(child, depth − 1, −β, −α, −color))
;        α := max(α, value)
;        if α ≥ β then
;            break (* cut-off *)
;    return value
;(* Initial call for Player A's root node *)
;negaMax(rootNode, depth, −∞, +∞, 1)


    SUBROUTINE

.doQ                lda #-1
                    sta __quiesceCapOnly
                    jsr quiesce
                    inc __quiesceCapOnly
                    rts


.exit               lda@PLY value
                    sta __negaMax
                    lda@PLY value+1
                    sta __negaMax+1
                    rts
                    

.terminal           cmp #0                          ; captured piece
                    bne .doQ                        ; last move was capture, so quiesce


    IF 0
    ; king moves will also quiesce
    ; theory is - we need to see if it was an illegal move

                    lda fromPiece
                    and #PIECE_MASK
                    cmp #KING
                    beq .doQ
    ENDIF
                        
                    lda Evaluation
                    sta __negaMax
                    lda Evaluation+1
                    sta __negaMax+1

.inCheck2           rts



    DEF negaMax

    ; PARAMS depth-1, -beta, -alpha
    ; pased through temporary variables (__alpha, __beta) and X reg

    ; pass...
    ; x = depthleft
    ; a = captured piece
    ; SET_BANK_RAM      --> current ply
    ; __alpha[2] = param alpha
    ; __beta[2] = param beta


        COMMON_VARS_ALPHABETA
        REFER selectmove
        VEND negaMax

                    pha

                    CALL ThinkBar
                    lda currentPly
                    sta SET_BANK_RAM

                    pla
                    dex
                    bmi .terminal
                    stx@PLY depthLeft


    ; Allow the player to force computer to select a move. Press the SELECT switch
    ; This may have issues if no move has been selected yet. Still... if you wanna cheat....

                    lda SWCHB
                    and #2
                    beq .exit                       ; SELECT abort
                    sta COLUPF                      ; grey thinkbars

                    lda __alpha
                    sta@PLY alpha
                    lda __alpha+1
                    sta@PLY alpha+1

                    lda __beta
                    sta@PLY beta
                    lda __beta+1
                    sta@PLY beta+1


    IF 1
                    lda Evaluation
                    adc randomness
                    sta Evaluation
                    bcc .evh
                    inc Evaluation+1
.evh
    ENDIF

                    jsr GenerateAllMoves
                    lda flagCheck
                    bne .inCheck2                           ; OTHER guy in check

    IF 1
                    lda@PLY moveIndex
                    bmi .none
                    lsr
                    lsr
                    lsr
                    lsr
                    lsr
                    adc Evaluation
                    sta Evaluation
                    lda Evaluation+1
                    adc #0
                    sta Evaluation+1
.none
    ENDIF


                    lda #<-INFINITY
                    sta@PLY value
                    lda #>-INFINITY
                    sta@PLY value+1

                    ldx@PLY moveIndex
                    bpl .forChild
                    jmp .exit
                    
.forChild           stx@PLY movePtr

                    jsr MakeMove



    ;        value := max(value, −negaMax(child, depth − 1, −β, −α, −color))

    ; PARAMS depth-1, -beta, -alpha
    ; pased through temporary variables (__alpha, __beta) and X reg

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


                    ldx@PLY depthLeft
                    lda@PLY capturedPiece

                    inc currentPly
                    ldy currentPly
                    sty SET_BANK_RAM                ; self-switch
                    
                    jsr negaMax

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    jsr unmakeMove

                    sec
                    lda #0
                    sbc __negaMax
                    sta __negaMax
                    lda #0
                    sbc __negaMax+1
                    sta __negaMax+1                 ; -negaMax(...)

                    lda flagCheck
                    beq .notCheck
                    
    ; at this point we've determined that the move was illegal, because the next ply detected
    ; a king capture. So, the move should be totally discounted

                    lda #0
                    sta flagCheck                   ; so we don't retrigger in future - it's been handled!
                    beq .nextMove                   ; unconditional - move is not considered!

.notCheck           sec
                    lda@PLY value
                    sbc __negaMax
                    lda@PLY value+1
                    sbc __negaMax+1
                    bvc .lab0
                    eor #$80
.lab0               bpl .lt0                        ; branch if value >= negaMax

    ; so, negaMax > value!

                    lda __negaMax
                    sta@PLY value
                    lda __negaMax+1
                    sta@PLY value+1                 ; max(value, -negaMax)

                    lda@PLY movePtr
                    sta@PLY bestMove
.lt0

;        α := max(α, value)

                    sec
                    lda@PLY value
                    sbc@PLY alpha
                    lda@PLY value+1
                    sbc@PLY alpha+1
                    bvc .lab1
                    eor #$80
.lab1               bmi .lt1                        ; value < alpha

                    lda@PLY value
                    sta@PLY alpha
                    lda@PLY value+1
                    sta@PLY alpha+1                 ; alpha = max(alpha, value)

.lt1

;        if α ≥ β then
;            break (* cut-off *)

                    sec
                    lda@PLY alpha
                    sbc@PLY beta
                    lda@PLY alpha+1
                    sbc@PLY beta+1
                    bvc .lab2
                    eor #$80
.lab2               bpl .retrn                      ; alpha >= beta


.nextMove           ldx@PLY movePtr
.nextX              dex
                    bmi .retrn
                    jmp .forChild

.retrn              jmp .exit


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "NEGAMAX"

;---------------------------------------------------------------------------------------------------
; EOF
