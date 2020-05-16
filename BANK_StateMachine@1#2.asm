    SLOT 1
    NEWBANK STATEMACHINE2


;---------------------------------------------------------------------------------------------------

    DEF aiChooseDebounce
    SUBROUTINE

        REFER AiStateMachine
        VEND aiChooseDebounce

    ; We've changed promotion piece, and drawn it
    ; wait for joystick to be released before continuing

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    bne .exit                       ; wait while joystick still pressed

                    lda #1
                    sta aiFlashDelay
                    sta aiFlashPhase

                    PHASE AI_ChoosePromotePiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiReselectDebounce
    SUBROUTINE

        REFER AiStateMachine
        VEND aiReselectDebounce

    ; We've just cancelled the move. Wait for the button to be released
    ; and then go back to selecting a piece to move

                    lda INPT4
                    bpl .exit                       ; button still pressed, so wait

                    PHASE AI_SelectStartSquare
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterMove
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDelayAfterMove

                    lda #50
                    sta aiFlashDelay
                    PHASE AI_DelayAfterMove2
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterMove2
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDelayAfterMove

                    dec aiFlashDelay
                    bne .exit
                    PHASE AI_MoveIsSelected
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterPlaced
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDelayAfterPlaced

                    ldx #75                         ; delay after human move
                    lda sideToMove
                    bmi .computer
                    ldx #1                          ; delay after computer move
.computer           stx aiFlashDelay

                    PHASE AI_DelayAfterPlaced2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterPlaced2
    SUBROUTINE          

        REFER AiStateMachine
        VEND aiDelayAfterPlaced2

                    dec aiFlashDelay
                    bne .exit

                    ;SWAP

                    PHASE AI_GenerateMoves
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchToTargetB

    ; now we want to undraw the piece in the old square

                    lda drawDelay
                    beq .stepOne
                    dec drawDelay
                    rts

.stepOne
                    lda lastSquareX12
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0          ; erase whatever was on the previous square (completely blank)

                    ldy lastSquareX12
                    lda previousPiece

                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM;@3
                    sta@RAM Board,y                 ; and what's actually moving there

                    lda lastPiece
                    sta previousPiece

                    PHASE AI_MarchB2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiPromotePawnStart
    SUBROUTINE

        REFER AiStateMachine
        VEND aiPromotePawnStart


                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE
                    bcc .exit

                    lda #0
                    sta aiFlashPhase
                    sta aiFlashDelay

                    ldy toX12
                    sty squareToDraw

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    and #PIECE_MASK
                    beq .empty

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0          ; remove any capturable piece for display purposes

.empty              PHASE AI_RollPromotionPiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiGenerateMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiGenerateMoves
    
                    lda toX12
                    sta squareToDraw                    ; for showing move (display square)

                    ldx sideToMove
                    bpl .player


.computer           PHASE AI_ComputerMove               ; computer select move
                    rts

                    
.player             PHASE AI_StartMoveGen
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStepMoveGen
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStepMoveGen

                    lda originX12                       ; location of cursor (show move)
                    sta cursorX12
                    PHASE AI_BeginSelectMovePhase
                    rts


;---------------------------------------------------------------------------------------------------

    align 256       ; TODO?
    DEF PositionSprites
    SUBROUTINE

        REFER StartupBankReset
        VEND PositionSprites


                    lda cursorX12
                    sec
.sub10              sbc #10
                    bcs .sub10
                    adc #8
                    tay

                    sta WSYNC                ; 00     Sync to start of scanline.

                    lda colToPixel,y

                    sec                      ; 02     Set the carry flag so no borrow will be applied during the division.
.divideby15         sbc #15                  ; 04     Waste the necessary amount of time dividing X-pos by 15!
                    bcs .divideby15          ; 06/07  11/16/21/26/31/36/41/46/51/56/61/66

                    tay
                    lda fineAdjustTable,y    ; 13 -> Consume 5 cycles by guaranteeing we cross a page boundary
                    sta HMP0
                    sta RESP0                ; 21/ 26/31/36/41/46/51/56/61/66/71 - Set the rough position.

                    sta WSYNC
                    sta HMOVE

                    rts

; This table converts the "remainder" of the division by 15 (-1 to -15) to the correct
; fine adjustment value. This table is on a page boundary to guarantee the processor
; will cross a page boundary and waste a cycle in order to be at the precise position
; for a RESP0,x write

fineAdjustBegin

            DC.B %01110000; Left 7
            DC.B %01100000; Left 6
            DC.B %01010000; Left 5
            DC.B %01000000; Left 4
            DC.B %00110000; Left 3
            DC.B %00100000; Left 2
            DC.B %00010000; Left 1
            DC.B %00000000; No movement.
            DC.B %11110000; Right 1
            DC.B %11100000; Right 2
            DC.B %11010000; Right 3
            DC.B %11000000; Right 4
            DC.B %10110000; Right 5
            DC.B %10100000; Right 6
            DC.B %10010000; Right 7

fineAdjustTable EQU fineAdjustBegin - %11110001; NOTE: %11110001 = -15


    ALLOCATE colToPixel, 8
    .byte 0,20,40,60,80,100,120,140


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetA
    SUBROUTINE

        REFER AiStateMachine

        VAR __fromRow, 1
        VAR __boardIndex, 1
        VAR __fromCol, 1
        VAR __toCol, 1

        VEND aiMarchToTargetA


                    lda drawDelay
                    beq .nodelay
                    dec drawDelay
                    rts
.nodelay

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
.unmovedx

                    lda originX12
                    sta cursorX12

                    PHASE AI_MarchA2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFinalFlash
    SUBROUTINE

        REFER AiStateMachine
        VEND aiFinalFlash

    ; Piece has finished the animated move and is now in destination square.
    ; Flash the piece

                    lda drawDelay
                    beq .deCount
                    dec drawDelay
                    rts

.deCount            lda drawCount
                    beq .flashDone2
                    dec drawCount

                    lda #10
                    sta drawDelay               ; "getting ready to move" flash

                    lda fromX12
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0
                    rts

.flashDone2

                    lda #100
                    sta aiFlashDelay

                    PHASE AI_SpecialMoveFixup
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartSquareSelected
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStartSquareSelected


    ; Mark all the valid moves for the selected piece on the board
    ; and then start pulsing the piece
    ; AND start choosing for selection of TO square

    ; Iterate the movelist and for all from squares which = drawPieceNumber
    ; then draw a BLANK at that square
    ; do 1 by one, when none found then increment state

                    lda cursorX12
                    sta squareToDraw

                    lda #10
                    sta aiFlashDelay

                    lda #0
                    sta toX12 ;aiToSquareX12
                    sta aiFlashPhase                ; for debounce exit timing

                    lda #-1
                    sta aiMoveIndex

                    lda #HOLD_DELAY
                    sta mdelay                      ; hold-down delay before moves are shown

                    PHASE AI_DrawMoves
                    rts


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_StateMachine2"

;---------------------------------------------------------------------------------------------------

; EOF
