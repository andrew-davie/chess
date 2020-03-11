    NEWBANK STATEMACHINE


; Banks holding data (ply 0 doubles as WHITE, and ply 1 as BLACK)

PLAYER              = RAMBANK_PLY
OPPONENT            = PLAYER + 1

CURSOR_MOVE_SPEED               = 16/2
CAP_SPEED                       = 16/2
HOLD_DELAY                      = 30/2

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

    MAC TM
    .byte {2}
    ENDM


ONCEPERFRAME = 40

    MAC TABDEF ; {1} = macro to use
        ; and per-line, {1} = #, {2} = name, {3} = time

    {1} BeginSelectMovePhase,       1
    {1} SelectStartSquare,          ONCEPERFRAME
    {1} StartSquareSelected,        ONCEPERFRAME
    {1} DrawMoves,                  ONCEPERFRAME
    {1} ShowMoveCaptures,           ONCEPERFRAME
    {1} SlowFlash,                  ONCEPERFRAME
    {1} UnDrawTargetSquares,        ONCEPERFRAME
    {1} SelectDestinationSquare,    ONCEPERFRAME
    {1} Quiescent,                  ONCEPERFRAME
    {1} ReselectDebounce,           ONCEPERFRAME
    {1} StartMoveGen,               ONCEPERFRAME
    {1} StepMoveGen,                ONCEPERFRAME
    {1} LookForCheck,               ONCEPERFRAME
    {1} StartClearBoard,            ONCEPERFRAME
    {1} ClearEachRow,               ONCEPERFRAME
    {1} DrawEntireBoard,            ONCEPERFRAME
    {1} DrawPart2,                  ONCEPERFRAME
    {1} DrawPart3,                  ONCEPERFRAME
    {1} FlipBuffers,                ONCEPERFRAME
    {1} GenerateMoves,              ONCEPERFRAME
    {1} ComputerMove,               ONCEPERFRAME
    {1} PrepForPhysicalMove,        ONCEPERFRAME
    {1} WriteStartPieceBlank,       ONCEPERFRAME
    {1} MarchToTargetA,             ONCEPERFRAME
    {1} MarchB,                     ONCEPERFRAME
    {1} MarchToTargetB,             ONCEPERFRAME
    {1} MarchB2,                    ONCEPERFRAME
    {1} FinalFlash,                 ONCEPERFRAME
    {1} SpecialMoveFixup,           ONCEPERFRAME
    {1} InCheckBackup,              ONCEPERFRAME
    {1} InCheckDelay,               ONCEPERFRAME
    {1} PromotePawnStart,           ONCEPERFRAME
    {1} RollPromotionPiece,         ONCEPERFRAME
    {1} ChoosePromotePiece,         ONCEPERFRAME
    {1} ChooseDebounce,             ONCEPERFRAME
    ENDM

    TABDEF AIN
    DEF AiVectorLO
    TABDEF LO
    DEF AiVectorHI
    TABDEF HI
    DEF AiVectorBANK
    TABDEF BK
    DEF AiTimeRequired
    TABDEF TM


;---------------------------------------------------------------------------------------------------

    DEF AiSetupVectors
    ;SUBROUTINE

    ; State machine vector setup - points to current routine to execute

                    ldx aiPhase

                    lda AiTimeRequired,x
                    cmp INTIM                       ; is there enough time left?
                    bcs .exit                       ; nope

                    lda AiVectorLO,x
                    sta __ptr
                    lda AiVectorHI,x
                    sta __ptr+1

                    lda AiVectorBANK,x
                    sta savedBank

                    clc
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartMoveGen
    SUBROUTINE

    ; To assist with castling, generate the moves for the opponent, giving us effectively
    ; a list of squares that are being attacked. The castling can't happen if the king is
    ; in check or if the squares it would have to move over are in check

    ; we don't need to worry about this if K has moved, or relevant R has moved or if
    ; the squares between are occupied. We can tell THAT by examining the movelist to see
    ; if there are K-moves marked "FLAG_CASTLE" - and the relevant squares

                    lda #OPPONENT
                    sta currentPly
                    jsr InitialiseMoveGeneration

                    lda sideToMove
                    eor #128
                    sta sideToMove              ; for movegen to know

                    PHASE AI_StepMoveGen
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStepMoveGen
    SUBROUTINE

    ; Because we're (possibly) running with the screen on, processing time is very short and
    ; we generate the opponent moves piece by piece. Time isn't really an isssue here, so
    ; this happens over multiple frames.

                    jsr GenerateOneMove
                    bcc .wait

                    lda sideToMove
                    eor #128
                    sta sideToMove

                    PHASE AI_LookForCheck
.wait               rts


;---------------------------------------------------------------------------------------------------

    DEF aiLookForCheck
    SUBROUTINE

    ; now we've finished generating the opponent moves
    ; See if the square our king is on is an attacked square (that is, it appears as a TO
    ; square in the opponent's movelist)

                    lda #PLAYER
                    sta currentPly
                    jsr SAFE_GetKingSquare          ; king's current X12 square

    inc currentPly
                    jsr SAFE_IsSquareUnderAttack
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

.exit               PHASE AI_BeginSelectMovePhase
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiInCheckBackup
    SUBROUTINE

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

                    dec mdelay
                    bne .exit

                    lda #0
                    sta COLUBK

                    PHASE AI_BeginSelectMovePhase
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiBeginSelectMovePhase
    SUBROUTINE


                    lda #$38
                    sta cursorX12

                    lda #0
                    sta mdelay              ;?
                    sta aiFlashPhase        ;?

                    lda #-1
                    sta aiFromSquareX12
                    sta aiToSquareX12

                    PHASE AI_SelectStartSquare
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

                    jsr moveCursor
                    jsr SAFE_IsValidMoveFromSquare

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


;          RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
 ;         0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111

    ALLOCATE JoyCombined, 16
    .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   1,  -1,   0

    ALLOCATE JoyMoveCursor, 16
    .byte     0,   0,   0,   0,   0,  -9,  11,   1,   0, -11,  9,  -1,   0,  -10,  10,   0

;---------------------------------------------------------------------------------------------------

    DEF aiStartSquareSelected
    SUBROUTINE

    ; Mark all the valid moves for the selected piece on the board
    ; and then start pulsing the piece
    ; AND start choosing for selection of TO square

    ; Iterate the movelist and for all from squares which = drawPieceNumber
    ; then draw a BLANK at that square
    ; do 1 by one, when none found then increment state

                    lda cursorX12
                    sta drawPieceNumberX12

                    lda #10
                    sta aiFlashDelay

                    lda #0
                    sta aiToSquareX12
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

    DEF aiUnDrawTargetSquares
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
.valid

                    jsr SAFE_showMoveOptions            ; draw potential moves one at a time
                    lda aiMoveIndex
                    bpl .exit                           ; still drawing in this phase

                    PHASE AI_SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------


    DEF aiShowMoveCaptures
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

        VAR __newCursor, 1

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

                    lda INPT4
                    bmi .noButton

                    lda aiToSquareX12
                    cmp aiFromSquareX12
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

    ; We've just cancelled the move. Wait for the button to be released
    ; and then go back to selecting a piece to move

                    lda INPT4
                    bpl .exit                       ; button still pressed, so wait

                    PHASE AI_SelectStartSquare
.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF aiQuiescent
    SUBROUTINE
    TAG MOVE_SELECTED

                    lda #-1
                    sta cursorX12

                    lda aiFromSquareX12
                    sta fromX12
                    sta originX12
                    lda aiToSquareX12
                    sta toX12

                    jsr SAFE_GetPiece

    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square


#if 0
                    ldx #0
                    lda aiPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    lda aiPiece
                    and #~FLAG_ENPASSANT            ; clear flag as it's been handled
                    sta aiPiece

                    ldx toX12                       ; this IS an en-passantable opening, so record the square
.noep               ;stx enPassantPawn               ; capturable square for en-passant move
#endif

    ; End of en-passant handling

                    lda aiPiece
                    sta fromPiece
                    ;ora #FLAG_MOVED                ; for K/R prevents usage in castling
                    ;sta toPiece



                    ldy fromX12
                    jsr GetBoard                    ; get the piece

                    eor fromPiece
                    and #PIECE_MASK                 ; if not the same piece board/movelist...
                    bne .promote                    ; promote a pawn

                    PHASE AI_PrepForPhysicalMove
                    rts

.promote            PHASE AI_PromotePawnStart
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiPromotePawnStart
    SUBROUTINE

                    lda #0
                    sta aiFlashPhase
                    sta aiFlashDelay

                    ldy aiToSquareX12
                    sty drawPieceNumberX12
                    jsr PromoteStart                ; remove any capturable piece for display purposes

                    PHASE AI_RollPromotionPiece
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiRollPromotionPiece
    SUBROUTINE

    ; Flash the '?' and wait for an UDLR move

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
                    jsr SAFE_showPromoteOptions

                    inc aiFlashPhase

.exit               rts


.even               lda #3                  ; QUEEN
                    sta aiPiece             ; cycles as index to NBRQ

                    inc aiFlashPhase

                    ldx #INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0        ;TODO: fix for colour
                    jsr SAFE_showPromoteOptions

                    PHASE AI_ChooseDebounce
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiChoosePromotePiece
    SUBROUTINE

    ; Question-mark phase has exited via joystick direction
    ; Now we cycle through the selectable pieces

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
                    lda aiPiece
                    adc JoyCombined,y
                    and #3
                    sta aiPiece

                    PHASE AI_ChooseDebounce         ; wait for release

.odd                dec aiFlashDelay
                    bpl .exit

.force              lda #10
                    sta aiFlashDelay

                    inc aiFlashPhase

                    ldy aiPiece
                    ldx promotePiece,y
                    jsr SAFE_showPromoteOptions

.exit               rts


.chosen
                    lda aiPiece
                    and #PIECE_MASK
                    tax

                    lda promoteType,x
                    sta fromPiece

                    ldy aiToSquareX12
                    jsr PromoteStart

                    PHASE AI_PrepForPhysicalMove
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

    CHECK_BANK_SIZE "BANK_StateMachine"


; EOF
