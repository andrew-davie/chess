    NEWBANK RECON

;---------------------------------------------------------------------------------------------------

    DEF UNSAFE_showP_MoveCaptures
    SUBROUTINE

        REFER SAFE_showP_MoveCaptures
        VAR __toSquareX12, 1
        VAR __fromPiece, 1
        VAR __aiMoveIndex, 1
        VEND UNSAFE_showP_MoveCaptures

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked

                    lda savedBank
                    pha

                    lda #BANK_UNSAFE_showP_MoveCaptures
                    sta savedBank


.next               ldx aiMoveIndex
                    stx __aiMoveIndex
                    bmi .skip                       ; no moves in list

                    lda INTIM
                    cmp #20
                    bcc .skip

                    dec aiMoveIndex

                    jsr GetP_MoveFrom
                    cmp fromX12
                    bne .next


                    jsr GetP_MoveTo
                    sta __toSquareX12
                    tay
                    jsr GetBoard
                    and #PIECE_MASK
                    beq .next

    ; There's something on the board at destination, so it's a capture
    ; Let's see if we are doing a pawn promote...

                    ldy fromX12
                    jsr GetBoard
                    sta __fromPiece

                    jsr GetP_MovePiece
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
                    sta squareToDraw

                    jsr CopySinglePiece

.skip               pla
                    sta savedBank
                    rts

restoreIndex        lda __aiMoveIndex
                    sta aiMoveIndex
                    jmp .skip


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetA
    SUBROUTINE

        REFER AiStateMachine
        VAR __fromRow, 1
        VAR __boardIndex, 1
        VAR __fromCol, 1
        VAR __toCol, 1
        VEND aiMarchToTargetA


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
                    sty squareToDraw

                    jsr GetBoard
                    cmp #0
                    beq .skipbl
                    jsr CopySinglePiece             ; erase next square along --> blank

.skipbl
                    ldy fromX12
                    sty __boardIndex

                    jsr GetBoard
                    sta lastPiece                   ; what we are overwriting
                    lda fromPiece
                    ora #FLAG_MOVED                ; prevents usage in castling for K/R
                    and #~FLAG_ENPASSANT
                    ldy __boardIndex
                    jsr PutBoard

                    PHASE AI_MarchB

.unmovedx
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB2
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchB2

                    ldy lastSquareX12
                    sty squareToDraw

                    jsr GetBoard
                    cmp #0
                    beq .skipbl2

                    jsr CopySinglePiece             ; draw previous piece back in old position
.skipbl2

                    lda fromX12
                    cmp toX12
                    beq xhalt

                    lda #0                          ; inter-move segment speed (can be 0)
                    sta drawDelay
                    PHASE AI_MarchToTargetA

                    rts

xhalt

                    ;??? jsr FinaliseMove

                    lda #4                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE AI_FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF FinaliseMove
    SUBROUTINE

        REFER aiMarchB2
        VEND FinaliseMove

    ; Now the visible movement on the board has happened, fix up the pointers to the pieces
    ; for both sides.

                    lda #BANK_FinaliseMove
                    sta savedBank

                    ;lda sideToMove
                    ;asl
                    ;lda #RAMBANK_PLY
                    ;adc #0
                    ;jsr GoFixPieceList

                    lda toX12
                    sta fromX12                     ; there MAY be no other-side piece at this square - that is OK!
                    sta originX12

                    lda #0
                    sta toX12                       ; --> deleted (square=0)

                    ;lda lastPiece
                    ;beq .notake

                    ;lda sideToMove
                    ;eor #128
                    ;asl
                    ;lda #RAMBANK_PLY
                    ;adc #0
                    ;jsr GoFixPieceList                ; REMOVE any captured object

.notake             rts
#endif


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchToTargetB

    ; now we want to undraw the piece in the old square

                    lda lastSquareX12
                    sta squareToDraw

                    jsr CopySinglePiece             ; erase whatever was on the previous square (completely blank)

                    ldy lastSquareX12
                    lda previousPiece
                    jsr PutBoard

                    lda lastPiece
                    sta previousPiece

                    PHASE AI_MarchB2
                    rts


;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------

    DEF CopySetupForMarker
    SUBROUTINE

        REFER markerDraw
        REFER showPromoteOptions
        VAR __pieceColour, 1
        VAR __oddeven, 1
        VAR __pmcol, 1
        VEND CopySetupForMarker

                    lda squareToDraw
                    sec
                    ldy #10
.sub10              sbc #10
                    dey
                    bcs .sub10
                    sty __oddeven
                    adc #8
                    sta __pmcol
                    adc __oddeven

                    and #1
                    eor #1
                    beq .white
                    lda #36
.white
                    sta __pieceColour               ; actually SQUARE black/white

                    txa
                    clc
                    adc __pieceColour
                    sta __pieceColour

                    lda __pmcol
                    and #3

                    clc
                    adc __pieceColour
                    tay
                    rts

;---------------------------------------------------------------------------------------------------

    DEF CopySetup
    SUBROUTINE

        REFER CopySinglePiece
        VAR __tmp, 1
        VAR __shiftx, 1
        VEND CopySetup

                    lda savedBank
                    pha
                    lda #BANK_CopySetup
                    sta savedBank

    ; figure colouration of square

                    lda squareToDraw
                    ldx #10
                    sec
.sub10              sbc #10
                    dex
                    bcs .sub10
                    adc #8
                    sta __shiftx
                    stx __tmp
                    adc __tmp


                    and #1
                    eor #1
                    beq .white
                    lda #36
.white              sta __pieceColour               ; actually SQUARE black/white

    ; PieceColour = 0 for white square, 36 for black square

                    ;lda #RAMBANK_BOARD
                    ;sta SET_BANK_RAM

                    ldy squareToDraw
                    jsr GetBoard ;lda Board,x
                    asl
                    bcc .blackAdjust
                    ora #16
.blackAdjust        lsr
                    and #%1111
                    tax

                    lda __shiftx
                    and #3                          ; shift position in P

                    clc
                    adc PieceToShape,x
                    clc
                    adc __pieceColour
                    tay

                    pla
                    sta savedBank
                    rts

PieceToShape

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KING_on_WHITE_SQUARE_0

    .byte INDEX_BLACK_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KING_on_WHITE_SQUARE_0

;---------------------------------------------------------------------------------------------------

 include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_BISHOP_on_BLACK_SQUARE_3.asm"
 include "gfx/BLACK_ROOK_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_ROOK_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_ROOK_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_ROOK_on_BLACK_SQUARE_3.asm"
 include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_QUEEN_on_BLACK_SQUARE_3.asm"
 include "gfx/BLACK_KING_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_KING_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_KING_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_KING_on_BLACK_SQUARE_3.asm"


 include "gfx/WHITE_MARKER_on_WHITE_SQUARE_3.asm"

    CHECK_BANK_SIZE "BANK_RECON"

; EOF
