

    NEWBANK STATEMACHINE


;---------------------------------------------------------------------------------------------------

STARTSELECTPIECE = 1

AI_BeginSelectMovePhase           = 0
AI_SelectStartSquare              = 1
AI_StartSquareSelected            = 2
AI_DrawMoves                      = 3
AI_ShowMoveCaptures               = 4
AI_SlowFlash                      = 5
AI_DrawTargetSquares              = 6
AI_SelectDestinationSquare        = 7
AI_Quiescent                      = 8
AI_Halt                           = 9
AI_ReselectDebounce               = 10

    MAC PHASE ;#
    lda #{1}
    sta aiPhase
    ENDM


AiVectorLO          .byte <aiBeginSelectMovePhase           ; 0
                    .byte <aiSelectStartSquare              ; 1
                    .byte <aiStartSquareSelected            ; 2
                    .byte <aiDrawMoves                      ; 3
                    .byte <aiShowMoveCaptures               ; 4
                    .byte <aiSlowFlash                      ; 5
                    .byte <aiDrawTargetSquares              ; 6
                    .byte <aiSelectDestinationSquare        ; 7
                    .byte <aiQuiescent                      ; 9
                    .byte <aiHalt                           ; 10
                    .byte <aiReselectDebounce               ; 11

AiVectorHI          .byte >aiBeginSelectMovePhase           ; 0
                    .byte >aiSelectStartSquare              ; 1
                    .byte >aiStartSquareSelected            ; 2
                    .byte >aiDrawMoves                      ; 3
                    .byte >aiShowMoveCaptures               ; 4
                    .byte >aiSlowFlash                      ; 5
                    .byte >aiDrawTargetSquares              ; 6
                    .byte >aiSelectDestinationSquare        ; 7
                    .byte >aiQuiescent                      ; 9
                    .byte >aiHalt                           ; 10
                    .byte >aiReselectDebounce               ; 11

;---------------------------------------------------------------------------------------------------

    DEF aiBeginSelectMovePhase ;#0
    SUBROUTINE

                    lda #4
                    sta highlight_row
                    sta highlight_row+1
                    sta highlight_col
                    sta highlight_col+1

                    lda #0
                    sta mdelay              ;?
                    sta aiFlashPhase        ;?

                    lda #-1
                    sta aiFromSquare
                    sta aiToSquare

                    PHASE AI_SelectStartSquare
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

                    jsr moveCursor
                    jsr SAFE_IsValidMoveFromSquare

                    dec ccur                        ; pulse colour for valid squares
                    jsr setCursorColours

                    cpy #-1
                    beq .noButton                   ; illegal square

                    lda aiFlashPhase
                    and #1
                    bne .noButton                   ; prevent EOR-error on flashing selected piece

                    lda INPT4
                    bmi .noButton
                    PHASE AI_StartSquareSelected
.noButton

                    rts

;---------------------------------------------------------------------------------------------------

    DEF setCursorPriority
    SUBROUTINE

                    tya
                    pha

#if 1

                    lda highlight_row
                    eor #7
                    asl
                    asl
                    asl
                    ora highlight_col
                    tax

                    jsr SAFE_Get64toX12Board
                    ldx #%100
                    cmp #0
                    bne .under
                    ldx #0
.under              stx CTRLPF                  ; UNDER
#endif

                    pla
                    tay
                    rts

;---------------------------------------------------------------------------------------------------

    DEF setCursorColours
    SUBROUTINE

    ; pass y=-1 if move is NOT in the movelist
    ; preserve y

                    lda #$44

                    cpy #-1
                    beq .writeCursorCol             ; NOT in the movelist

                    lda ccur
                    lsr
                    lsr
                    and #7
                    ora #$C0

.writeCursorCol     sta COLUP0
                    rts


    OPTIONAL_PAGEBREAK "Joystik Tables", 32

;                      RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
;                      0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111
JoyMoveX        .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   0,   0,   0
JoyMoveY        .byte     0,   0,   0,   0,   0,   1,  -1,   0,   0,   1,  -1,   0,   0,   1,  -1,   0

;---------------------------------------------------------------------------------------------------

    DEF aiStartSquareSelected ;#2
    SUBROUTINE

    ; Mark all the valid moves for the selected piece on the board
    ; and then start pulsing the piece
    ; AND start choosing for selection of TO square



    ; Iterate the movelist and for all from squares which = drawPieceNumber
    ; then draw a BLANK at that square
    ; do 1 by one, when none found then increment state

                    lda highlight_row
                    eor #7
                    asl
                    asl
                    asl
                    ora highlight_col
                    sta drawPieceNumber

                    lda #10
                    sta aiFlashDelay
                    lda #0
                    sta aiToSquare
                    sta aiFlashPhase                ; for debounce exit timing

                    lda #-1
                    sta aiMoveIndex

                    lda #15
                    sta mdelay                      ; hold-down delay before moves are shown

                    PHASE AI_DrawMoves
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiDrawMoves
    SUBROUTINE


                    dec ccur
                    jsr setCursorColours

                    dec mdelay
                    bne .exit
                    lda #1
                    sta mdelay                          ; once triggered, runs always


                    lda aiMoveIndex
                    bpl .valid

                    jsr SAFE_getMoveIndex
                    sta aiMoveIndex

.valid              jsr SAFE_showMoveOptions            ; draw potential moves one at a time
                    lda aiMoveIndex
                    bpl .unsure                         ; still drawing in this phase

                    lda #CAP_SPEED
                    sta mdelay

                    lda #0
                    sta aiFlashPhase                    ; controls odd/even exit of flashing

                    PHASE AI_ShowMoveCaptures
                    rts

.exit

    ; Initial piece selection has happened, but the button hasn't been released yet
    ; AND we're still in the waiting phase to see if the button was held long enough for move show

                    lda INPT4
                    bpl .unsure                         ; button still pressed, so still unsure what to do

    ; Aha! Button released, so we know the selected piece and can start flashing it
    ; and allowing movement of the selector to a destination square...

                    PHASE AI_SelectDestinationSquare

.unsure             rts

;---------------------------------------------------------------------------------------------------

    DEF aiDrawTargetSquares
    SUBROUTINE

                    dec ccur
                    jsr setCursorColours

                    dec mdelay
                    bne .exit
                    lda #1
                    sta mdelay                          ; once triggered, runs always

                    lda aiMoveIndex
                    bpl .valid

                    jsr SAFE_getMoveIndex
                    sta aiMoveIndex

.valid              jsr SAFE_showMoveOptions            ; draw potential moves one at a time
                    lda aiMoveIndex
                    bpl .exit                           ; still drawing in this phase

                    PHASE AI_SelectStartSquare

.exit               rts

;---------------------------------------------------------------------------------------------------

CAP_SPEED           = 8

    DEF aiShowMoveCaptures ;#4
    SUBROUTINE

    ; draw/undraw ALL captured pieces
    ; we should do this an even number of times so that pieces don't disappEOR

                    dec ccur
                    jsr setCursorColours

                    dec mdelay                  ; flash speed UNVARYING despite draw happening

                    lda aiMoveIndex
                    bpl .valid                  ; guaranteed -1 on 1st call
                    jsr SAFE_getMoveIndex
                    sta aiMoveIndex

.valid              ;lda INTIM
                    ;cmp #22
                    ;bcc .exit                  ; try to prevent time overflows

                    jsr SAFE_showMoveCaptures
                    lda aiMoveIndex
                    bpl .exit

                    inc aiFlashPhase

                    PHASE AI_SlowFlash

.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF aiSlowFlash ;#5
    SUBROUTINE

    ; Joystick button is held down, so we're displaying the available moves
    ; They have all been drawn, so now we "slow" flash any pieces that can be captures

                    dec ccur
                    jsr setCursorColours

                    lda aiFlashPhase
                    and #1
                    bne .notEven                ; only exit after even # EOR-draws

                    lda INPT4
                    bmi .butpress               ; exit on button release

.notEven

    ; Wait for delay to expire then back and flash 'em again

                    dec mdelay
                    bpl .slowWait

                    lda #CAP_SPEED
                    sta mdelay

                    PHASE AI_ShowMoveCaptures       ; go back and rEORdraw all captures again

.slowWait           rts


.butpress           lda #1
                    sta mdelay

                    PHASE AI_DrawTargetSquares
                    rts


;---------------------------------------------------------------------------------------------------


    DEF moveCursor
    SUBROUTINE

    ; Part (a) move cursor around the board waiting for joystick press

                    dec mdelay
                    bpl .delaym

                    lda SWCHA
                    lsr
                    lsr
                    lsr
                    lsr
                    tay

                    clc
                    lda highlight_row
                    adc JoyMoveY,y
                    cmp #$8
                    bcs .abandon
                    sta highlight_row
.abandon
                    clc
                    lda highlight_col
                    adc JoyMoveX,y
                    cmp #$8
                    bcs .abandon2
                    sta highlight_col
.abandon2

                    lda #5
                    sta mdelay

                    jsr setCursorPriority


.delaym             rts


;---------------------------------------------------------------------------------------------------

    DEF FlashPiece
    SUBROUTINE

    ; Flash the selected piece

                    dec aiFlashDelay
                    bne .noFlashAi

                    inc aiFlashPhase

                    lda #10
                    sta aiFlashDelay

                    jsr SAFE_CopySinglePiece

.noFlashAi          rts

;---------------------------------------------------------------------------------------------------

    DEF aiSelectDestinationSquare
    SUBROUTINE

    ; Piece is selected and now we're looking for a button press on a destination square
    ; we flash the piece on-and-off while we're doing that

                    jsr FlashPiece
                    jsr moveCursor
                    jsr SAFE_IsValidMoveToSquare
                    jsr setCursorColours

    ; y = valid square

                    lda aiFlashPhase
                    and #1
                    bne .noButton                   ; prevent EOR-error on flashing selected piece

                    lda INPT4
                    bmi .noButton

                    cpy #-1
                    bne .done                       ; valid square

                    lda aiToSquare
                    cmp aiFromSquare                ; is to==from?  that's a cancelllation
                    bne .noButton                   ; no, so it's an INVALID square

                    PHASE AI_ReselectDebounce
                    rts

.done               PHASE AI_Quiescent              ; destination selected!

.noButton           rts


;---------------------------------------------------------------------------------------------------

    DEF aiReselectDebounce
    SUBROUTINE

    ; We've just cancelled the move. Wait for the button to be released
    ; and then go back to selecting a piece to move

                    lda INPT4
                    bpl .exit                       ; button still pressed, so wait

                    PHASE AI_SelectStartSquare
.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF aiQuiescent ;#10
    SUBROUTINE

                    lda #-1
                    sta highlight_row ;??? piece move error when removed...???!

                    lda aiFromSquare
                    sta fromSquare
                    lda aiToSquare
                    sta toSquare
                    lda aiPiece
                    sta fromPiece
                    sta toPiece

                    lda aiFromSquareX12
                    sta fromX12
                    lda aiToSquareX12
                    sta toX12

                    PHASE AI_Halt
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiHalt
    SUBROUTINE

    ; Effectively halt at this point until the other state machine resets the AI state machine

                    rts

;---------------------------------------------------------------------------------------------------

;    align 256
    DEF PositionSprites
    SUBROUTINE

                    ldy highlight_col

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


            align 256

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


    OPTIONAL_PAGEBREAK "colToPixel", 8
colToPixel          .byte 0,20,40,60,80,100,120,140

    CHECK_BANK_SIZE "BANK_StateMachine"


; EOF
