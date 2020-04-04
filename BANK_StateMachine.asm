    NEWBANK STATEMACHINE


; Banks holding data (ply 0 doubles as WHITE, and ply 1 as BLACK)

PLAYER              = RAMBANK_PLY
OPPONENT            = PLAYER + 1

CURSOR_MOVE_SPEED               = 16
CAP_SPEED                       = 20
HOLD_DELAY                      = 40


;---------------------------------------------------------------------------------------------------

P SET 0
    MAC AIN
AI_{1} SET P
P SET P+1
    ENDM

    MAC LO
    .byte <ai{1}
    ENDM

    MAC HI
    .byte >ai{1}
    ENDM

    MAC BK
    .byte BANK_ai{1}
    ENDM


ONCEPERFRAME = 40

    MAC TABDEF ; {1} = macro to use
        
        {1} BeginSelectMovePhase
        {1} SelectStartSquare
        {1} StartSquareSelected
        {1} DrawMoves
        {1} ShowMoveCaptures
        {1} SlowFlash
        {1} UnDrawTargetSquares
        {1} SelectDestinationSquare
        {1} Quiescent
        {1} ReselectDebounce
        {1} StartMoveGen
        {1} StepMoveGen
        {1} LookForCheck
        {1} StartClearBoard
        {1} ClearEachRow
        {1} DrawEntireBoard
        {1} DrawPart2
        {1} DrawPart3
        {1} FlipBuffers
        {1} GenerateMoves
        {1} ComputerMove
        {1} MoveIsSelected
        {1} WriteStartPieceBlank
        {1} MarchToTargetA
        {1} MarchB
        {1} MarchToTargetB
        {1} MarchB2
        {1} FinalFlash
        {1} SpecialMoveFixup
        {1} InCheckBackup
        {1} InCheckDelay
        {1} PromotePawnStart
        {1} RollPromotionPiece
        {1} ChoosePromotePiece
        {1} ChooseDebounce

    ENDM

    TABDEF AIN

    DEF AiVectorLO
        TABDEF LO

    DEF AiVectorHI
        TABDEF HI

    DEF AiVectorBANK
        TABDEF BK


;---------------------------------------------------------------------------------------------------

    DEF AiSetupVectors
    SUBROUTINE

        REFER AiStateMachine
        VEND AiSetupVectors

    ; State machine vector setup - points to current routine to execute

                    ldx aiState
                    lda AiVectorLO,x
                    sta __ptr
                    lda AiVectorHI,x
                    sta __ptr+1

                    lda AiVectorBANK,x
                    sta savedBank

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartMoveGen
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStartMoveGen

    ; To assist with castling, generate the moves for the opponent, giving us effectively
    ; a list of squares that are being attacked. The castling can't happen if the king is
    ; in check or if the squares it would have to move over are in check

    ; we don't need to worry about this if K has moved, or relevant R has moved or if
    ; the squares between are occupied. We can tell THAT by examining the movelist to see
    ; if there are K-moves marked "FLAG_CASTLE" - and the relevant squares

                    inc currentPly
                    jsr InitialiseMoveGeneration

                    lda sideToMove
                    eor #128
                    sta sideToMove              ; for movegen to know

                    PHASE AI_StepMoveGen
                    rts


;---------------------------------------------------------------------------------------------------


    DEF aiLookForCheck
    SUBROUTINE

        REFER AiStateMachine
        VEND aiLookForCheck

                    dec currentPly


#if 0

    ; now we've finished generating the opponent moves
    ; See if the square our king is on is an attacked square (that is, it appears as a TO
    ; square in the opponent's movelist)

                    
                    jsr SAFE_GetKingSquare          ; king's current X12 square

                    inc currentPly
                    jsr Go_IsSquareUnderAttack
                    dec currentPly
                    bcc .exit

    ; in check!

                    lda #$40
                    sta COLUBK

                    lda #50
                    sta mdelay

                    lda #8
                    sta drawCount               ; row #

                    PHASE AI_InCheckBackup
                    rts
#endif

.exit               PHASE AI_BeginSelectMovePhase
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiInCheckBackup
    SUBROUTINE

        REFER AiStateMachine
        VEND aiInCheckBackup

    ; We're about to draw some large text on the screen
    ; Make a backup copy of all of the row bitmaps, so that we can restore once text is done

                    dec drawCount
                    bmi .exit                   ; done all rows
                    ldy drawCount
                    jmp SAFE_BackupBitmaps

.exit               PHASE AI_InCheckDelay
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiInCheckDelay
    SUBROUTINE

        REFER AiStateMachine
        VEND aiInCheckDelay

                    dec mdelay
                    bne .exit

                    lda #0
                    sta COLUBK

                    PHASE AI_BeginSelectMovePhase
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiBeginSelectMovePhase
    SUBROUTINE

        REFER AiStateMachine
        VEND aiBeginSelectMovePhase

                    lda #$38
                    sta cursorX12

                    lda #0
                    sta mdelay              ;?
                    sta aiFlashPhase        ;?

                    lda #-1
                    sta fromX12
                    sta toX12
                    
                    PHASE AI_SelectStartSquare
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSelectStartSquare

                    jsr moveCursor
                    jsr IsValidMoveFromSquare

                    dec ccur                        ; pulse colour for valid squares
                    jsr setCursorColours

                    tya
                    ora INPT4
                    bmi .exit                       ; illegal square or no button press

                    PHASE AI_StartSquareSelected

.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF setCursorPriority
    SUBROUTINE

        REFER moveCursor
        VEND setCursorPriority

                    tya
                    pha

                    ldx #%100

                    ldy cursorX12
                    bmi .under
                    jsr GetBoard
                    cmp #0
                    bne .under
                    ldx #0
.under              stx CTRLPF                  ; UNDER

                    pla
                    tay
                    rts

;---------------------------------------------------------------------------------------------------

    DEF setCursorColours
    SUBROUTINE

        REFER aiSelectStartSquare
        REFER aiDrawMoves
        REFER aiUnDrawTargetSquares
        REFER aiShowMoveCaptures
        REFER aiSlowFlash
        REFER aiSelectDestinationSquare
        VEND setCursorColours

    ; pass y=-1 if move is NOT in the movelist
    ; preserve y

                    lda #$44

                    cpy #-1
                    beq .writeCursorCol             ; NOT in the movelist

                    lda ccur
                    lsr
                    lsr
                    lsr
                    and #3
                    clc
                    adc #$C0 ;COLOUR_LINE_1

.writeCursorCol     sta COLUP0
                    rts


;---------------------------------------------------------------------------------------------------

;          RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
;          0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111

    ALLOCATE JoyCombined, 16
    .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   1,  -1,   0

    ALLOCATE JoyMoveCursor, 16
    .byte     0,   0,   0,   0,   0,  -9,  11,   1,   0, -11,  9,  -1,   0,  -10,  10,   0


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

    DEF aiDrawMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawMoves

                    dec ccur
                    jsr setCursorColours

                    dec mdelay
                    bne .exit
                    lda #1                              ; larger number will slow the draw of available moves
                    sta mdelay                          ; once triggered, runs always

                    lda aiMoveIndex
                    bpl .valid
                    jsr SAFE_getMoveIndex
                    sta aiMoveIndex
.valid

                    jsr SAFE_showMoveOptions            ; draw potential moves one at a time
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

                    lda #6*4
                    sta ccur                            ; bright green square for selection

                    PHASE AI_SelectDestinationSquare

.unsure             rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_showMoveOptions
    SUBROUTINE

        REFER aiDrawMoves
        REFER aiUnDrawTargetSquares
        VAR __saveIdx, 1
        VAR __piece, 1
        VEND SAFE_showMoveOptions

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)

.next               ldx aiMoveIndex
                    stx __saveIdx
                    bmi .skip

                    lda INTIM
                    cmp #5
                    bcc .skip

                    dec aiMoveIndex

                    jsr GetMoveFrom
                    cmp fromX12
                    bne .next

                    jsr GetMoveTo
                    sta squareToDraw

                    jsr GetMovePiece
                    sta __piece

    ; If it's a pawn promote (duplicate "to" AND piece different (TODO) then skip others)

.sk                 dex
                    bmi .prom
                    jsr GetMoveTo
                    cmp squareToDraw
                    bne .prom
                    jsr GetMovePiece
                    eor __piece
                    and #PIECE_MASK
                    beq .prom                       ; same piece type so not a promote

                    dec aiMoveIndex
                    dec aiMoveIndex
                    dec aiMoveIndex
.prom

                    ldy squareToDraw
                    jsr GetBoard
                    and #PIECE_MASK
                    bne .next                       ; don't draw dots on captures - they are flashed later


                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE
                    bcc .skip

                    ;lda aiMoveIndex
                    ;sta __saveIdx

                    jsr markerDraw
                    rts

.skip               lda __saveIdx
                    sta aiMoveIndex
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiUnDrawTargetSquares
    SUBROUTINE

        REFER AiStateMachine
        VEND aiUnDrawTargetSquares


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
.valid

                    jsr SAFE_showMoveOptions            ; draw potential moves one at a time
                    lda aiMoveIndex
                    bpl .exit                           ; still drawing in this phase

                    PHASE AI_SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------


    DEF aiShowMoveCaptures
    SUBROUTINE

        REFER AiStateMachine
        VEND aiShowMoveCaptures

    ; draw/undraw ALL captured pieces
    ; we should do this an even number of times so that pieces don't disappEOR

                    dec ccur
                    jsr setCursorColours

                    dec mdelay                  ; flash speed UNVARYING despite draw happening

                    lda aiMoveIndex
                    bpl .valid                  ; guaranteed -1 on 1st call
                    jsr SAFE_getMoveIndex
                    sta aiMoveIndex
.valid

                    jsr SAFE_showMoveCaptures
                    lda aiMoveIndex
                    bpl .exit

                    inc aiFlashPhase

                    PHASE AI_SlowFlash

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSlowFlash
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSlowFlash

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

                    PHASE AI_UnDrawTargetSquares
                    rts


;---------------------------------------------------------------------------------------------------

    DEF moveCursor
    SUBROUTINE

        REFER aiSelectStartSquare
        REFER aiSelectDestinationSquare
        VAR __newCursor, 1
        VEND moveCursor

    ; Part (a) move cursor around the board waiting for joystick press


                    lda SWCHA
                    lsr
                    lsr
                    lsr
                    lsr
                    tay

                    cmp #15
                    beq .cursor             ; nothing pressed - skip delays

                    dec mdelay
                    bpl .delaym

                    clc
                    lda cursorX12
                    adc JoyMoveCursor,y
                    sta __newCursor
                    tay
                    jsr GetValid
                    cmp #-1
                    beq .invalid
                    lda __newCursor
                    sta cursorX12
.invalid

                    lda #CURSOR_MOVE_SPEED
                    sta mdelay
                    jsr setCursorPriority
                    rts


.cursor             lda #0
                    sta mdelay
                    jsr setCursorPriority

.delaym             rts


;---------------------------------------------------------------------------------------------------

    DEF FlashPiece
    SUBROUTINE

        REFER aiSelectDestinationSquare
        VEND FlashPiece

    ; Flash the selected piece

                    dec aiFlashDelay
                    bne .exit                       ; don't flash
                    lda #CAP_SPEED
                    sta aiFlashDelay

                    inc aiFlashPhase

                    jsr CopySinglePiece

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectDestinationSquare
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSelectDestinationSquare

    ; Piece is selected and now we're looking for a button press on a destination square
    ; we flash the piece on-and-off while we're doing that

                    jsr FlashPiece

        lda INTIM
        cmp #20
        bcc .noButton

                    jsr moveCursor

                    ldy cursorX12
                    sty toX12 

                    jsr GetPiece
                    jsr setCursorColours


    ; y = valid square

                    lda INPT4
                    bmi .noButton

                    lda toX12
                    cmp fromX12
                    beq .cancel

                    cpy #-1
                    beq .noButton                   ; not a valid square

                    lda aiFlashPhase
                    and #1
                    beq .done
                    sta aiFlashDelay                 ; EOR-phase incorrect - force quick fix to allow next-frame button detect
                    rts

.cancel

                    lda aiFlashPhase
                    and #1
                    beq .doCancel

    ; EOR-phase incorrect - force quick fix to allow next-frame button detect

                    lda #1
                    sta aiFlashDelay
                    rts


.doCancel           PHASE AI_ReselectDebounce
                    rts

.done               PHASE AI_Quiescent              ; destination selected!
.noButton           rts


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

    DEF aiQuiescent
    SUBROUTINE

        REFER AiStateMachine
        VEND aiQuiescent

    ; Move has been selected

                    lda #-1
                    sta cursorX12

                    lda fromX12
                    sta originX12
                    jsr GetPiece                    ; from the movelist

                    ldy fromX12
                    jsr GetBoard                    ; get the piece from the board itself

                    eor fromPiece
                    and #PIECE_MASK                 ; if not the same piece board/movelist...
                    bne .promote                    ; promote a pawn

                    PHASE AI_MoveIsSelected
                    rts

.promote            PHASE AI_PromotePawnStart
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

                    jsr CopySinglePiece             ; remove any capturable piece for display purposes

.empty              PHASE AI_RollPromotionPiece
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiRollPromotionPiece
    SUBROUTINE

        REFER AiStateMachine
        VEND aiRollPromotionPiece

    ; Flash the '?' and wait for an UDLR move

                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE
                    bcc .exit

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .nojoy

                    lda #0
                    sta aiFlashDelay

                    lda aiFlashPhase
                    and #1
                    beq .even

.nojoy              dec aiFlashDelay
                    bpl .exit

                    lda #10
                    sta aiFlashDelay

                    ldx #INDEX_WHITE_PROMOTE_on_WHITE_SQUARE_0
                    lda sideToMove
                    bpl .wtm
                    ldx #INDEX_BLACK_PROMOTE_on_WHITE_SQUARE_0
.wtm
                    jsr showPromoteOptions

                    inc aiFlashPhase

.exit               rts


.even               lda #3                          ; QUEEN
                    sta fromPiece                   ; cycles as index to NBRQ

                    inc aiFlashPhase


                    ldx #INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0        ;TODO: fix for colour
                    lda sideToMove
                    bpl .whiteToMove
                    ldx #INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
.whiteToMove

                    jsr showPromoteOptions

                    PHASE AI_ChooseDebounce
                    rts


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

                    jsr CopySinglePiece                     ; put back whatever was there to start

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

    align 256
    DEF PositionSprites
    SUBROUTINE

        REFER Reset
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

 include "gfx/BLACK_MARKER_on_BLACK_SQUARE_0.asm"
 include "gfx/BLACK_MARKER_on_BLACK_SQUARE_1.asm"
 include "gfx/BLACK_MARKER_on_BLACK_SQUARE_2.asm"
 include "gfx/BLACK_MARKER_on_BLACK_SQUARE_3.asm"
 include "gfx/BLACK_MARKER_on_WHITE_SQUARE_0.asm"
 include "gfx/BLACK_MARKER_on_WHITE_SQUARE_1.asm"
 include "gfx/BLACK_MARKER_on_WHITE_SQUARE_2.asm"
 include "gfx/BLACK_MARKER_on_WHITE_SQUARE_3.asm"

;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_StateMachine"


;---------------------------------------------------------------------------------------------------

; EOF
