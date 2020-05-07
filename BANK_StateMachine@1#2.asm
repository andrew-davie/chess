    SLOT 1
    NEWBANK STATEMACHINE2

;---------------------------------------------------------------------------------------------------

    DEF aiChoosePromotePiece
    SUBROUTINE

        REFER AiStateMachine
        VEND aiChoosePromotePiece

    ; Question-mark phase has exited via joystick direction
    ; Now we cycle through the selectable pieces

                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE
                    bcc .exit

                    lda INPT4
                    bmi .nobut                      ; no press

    ; button pressed but make sure phase is correct for exit

                    lda #0
                    sta aiFlashDelay

                    lda aiFlashPhase
                    and #1
                    beq .chosen                     ; button pressed --> selection made

.nobut
                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .odd                        ; no direction pressed

                    lsr
                    lsr
                    lsr
                    lsr
                    tay

    ; joystick but make sure phase is correct

                    lda aiFlashPhase
                    lsr
                    bcs .odd                        ; must wait until piece undrawn

    ; cycle to the next promotable piece (N/B/R/Q)
    ; TODO; use joy table for mod instead of just incrementing all the time

                    ;clc
                    lda fromPiece
                    adc JoyCombined,y
                    and #3
                    sta fromPiece

                    PHASE AI_ChooseDebounce         ; wait for release

.odd                dec aiFlashDelay
                    bpl .exit

.force              lda #10
                    sta aiFlashDelay

                    inc aiFlashPhase

                    ldy fromPiece
                    ldx promotePiece,y
                    jsr showPromoteOptions

.exit               rts


.chosen
                    lda fromPiece
                    and #PIECE_MASK
                    tax

                    lda promoteType,x
                    sta fromPiece

                    ldy toX12
                    jsr GetBoard
                    and #PIECE_MASK
                    beq .nothing

                    jsr CopySinglePiece;@0          ; put back whatever was there to start

.nothing            PHASE AI_MoveIsSelected
                    rts

    ALLOCATE promotePiece, 4
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0

    ALLOCATE promoteType,4
    .byte KNIGHT, BISHOP, ROOK, QUEEN


;---------------------------------------------------------------------------------------------------

    DEF aiChooseDebounce
    SUBROUTINE

        REFER AiStateMachine
        VEND aiChooseDebounce

    ; We've changed promotion piece, but wait for joystick to be released

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    bne .exit                       ; wait while joystick still pressed

                    lda #1
                    sta aiFlashDelay

                    PHASE AI_ChoosePromotePiece
.exit               rts


;---------------------------------------------------------------------------------------------------

        DEF aiDelayAfterMove
        SUBROUTINE

            VEND aiDelayAfterMove

                    lda #50
                    sta aiFlashDelay
                    PHASE AI_DelayAfterMove2
.exit               rts


;---------------------------------------------------------------------------------------------------

        DEF aiDelayAfterMove2
        SUBROUTINE

            VEND aiDelayAfterMove

                    dec aiFlashDelay
                    bne .exit
                    PHASE AI_MoveIsSelected
.exit               rts


;---------------------------------------------------------------------------------------------------

        DEF aiDelayAfterPlaced
        SUBROUTINE

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

        ;jsr debug

                    dec aiFlashDelay
                    bne .exit
                    PHASE AI_GenerateMoves
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchToTargetB

    ; now we want to undraw the piece in the old square

                    lda lastSquareX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0          ; erase whatever was on the previous square (completely blank)

                    ldy lastSquareX12
                    lda previousPiece
                    jsr PutBoard

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

                    jsr GetBoard
                    and #PIECE_MASK
                    beq .empty

                    jsr CopySinglePiece;@0          ; remove any capturable piece for display purposes

.empty              PHASE AI_RollPromotionPiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiGenerateMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiGenerateMoves
    
    ; Player comes here at the start of making a move
    ; This generates a valid movelist by calling 'negaMax' (removing illegal moves)
 rts ;tmp
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

    align 256
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


    CHECK_BANK_SIZE "BANK_StateMachine2"


;---------------------------------------------------------------------------------------------------

; EOF
