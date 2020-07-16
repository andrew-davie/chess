;---------------------------------------------------------------------------------------------------
; @1 STATE MACHINE #2.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 1
    ROMBANK STATEMACHINE2


;---------------------------------------------------------------------------------------------------

    DEF aiChooseDebounce
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE ChoosePromotePiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiReselectDebounce
    SUBROUTINE

        REF AiStateMachine
        VEND aiReselectDebounce

    ; We've just cancelled the move. Wait for the button to be released
    ; and then go back to selecting a piece to move

                    lda INPT4
                    bpl .exit                       ; button still pressed, so wait

                    PHASE SelectStartSquare
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterMove
    SUBROUTINE

        REF AiStateMachine
        VEND aiDelayAfterMove

                    lda #50
                    sta aiFlashDelay
                    PHASE DelayAfterMove2
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterMove2
    SUBROUTINE

        REF AiStateMachine
        VEND aiDelayAfterMove

                    dec aiFlashDelay
                    bne .exit
                    PHASE MoveIsSelected
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterPlaced
    SUBROUTINE

        REF AiStateMachine
        VEND aiDelayAfterPlaced

                    ldx #75                         ; delay after human move
                    lda sideToMove
                    asl
                    bmi .human
                    ldx #1                          ; delay after computer move
.human              stx aiFlashDelay

                    PHASE DelayAfterPlaced2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDelayAfterPlaced2
    SUBROUTINE          

        REF AiStateMachine
        VEND aiDelayAfterPlaced2


                    lda SWCHB
                    and #SELECT_SWITCH
                    bne .noSwapside

                    PHASE DebounceSelect
                    rts
.noSwapside


                    dec aiFlashDelay
                    bne .exit

                    ;SWAP

                    PHASE GenerateMoves
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
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

                    PHASE MarchB2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiPromotePawnStart
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiPromotePawnStart


                    lda INTIM
                    cmp #SPEEDOF_CopySinglePiece
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

.empty              PHASE RollPromotionPiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiGenerateMoves
    SUBROUTINE

        REF AiStateMachine
        VEND aiGenerateMoves

;            CALL Breaker
    
                    lda toX12
                    sta squareToDraw                    ; for showing move (display square)

                    lda sideToMove
                    asl
                    bmi .player


.computer           PHASE ComputerMove               ; computer select move
                    rts

                    
.player             PHASE StartMoveGen
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStepMoveGen
    SUBROUTINE

        REF AiStateMachine
        VEND aiStepMoveGen

                    lda originX12                       ; location of cursor (show move)
                    sta cursorX12
                    PHASE BeginSelectMovePhase
                    rts


;---------------------------------------------------------------------------------------------------

    align 256       ; TODO?


    DEF PositionSprites
    SUBROUTINE

        REF StartupBankReset
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

        REF AiStateMachine

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

                    PHASE MarchA2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFinalFlash
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiFinalFlash

    ; Piece has finished the animated move and is now in destination square.
    ; Flash the piece


    ; TODO: if en-passant, we can remove the piece being taken
    ; check movePiece for enPassant flag set (x)


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

                    PHASE SpecialMoveFixup
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartSquareSelected
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE DrawMoves
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiWriteStartPieceBlank
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiWriteStartPieceBlank

    ; Flash the piece in-place preparatory to moving it.
    ; drawDelay = flash speed
    ; drawCount = # of flashes


                    lda #%100
                    sta CTRLPF

                    ldx platform
                    lda startCol,x
                    sta COLUP0


                    lda drawDelay
                    beq deCount
                    dec drawDelay
                    rts

startCol
    .byte NTSC_COLOUR_LINE_2-2, PAL_COLOUR_LINE_2-2



deCount

                    lda drawCount
                    beq flashDone
                    dec drawCount

                    lda #READY_TO_MOVE_FLASH
                    sta drawDelay                   ; "getting ready to move" flash

                    lda fromX12
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jmp CopySinglePiece;@0          ; EOR-draw = flash

flashDone

                    ;lda #2
                    ;sta drawDelay
                    PHASE MarchToTargetA
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiEPHandler
    SUBROUTINE

                    ;CALL EnPassantFixupDraw         ; set enPassantPawn


                    lda fromPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT|FLAG_MOVED
                    bne .exit

    ; we have deteced a piece DOING an en passant capture
    ; so do the actual removal of the captured pawn...
    ; calculate the captured pawn's square based on piece colour

                    lda #-10
                    ldx fromPiece
                    bpl .white
                    lda #10
.white
                    clc
                    adc fromX12                     ; attacker destination square
                    sta enPassantPawn               ; now this is the pawn to ERASE

                    lda #5                          ; on/off count (leave undrawn)
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE EPFlash
                    rts


.exit
            
                    lda #4                          ; on/off count (leave undrawn)
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------

    END_BANK
    
;---------------------------------------------------------------------------------------------------
; EOF
