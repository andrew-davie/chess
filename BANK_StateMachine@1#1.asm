    SLOT 1
    NEWBANK STATEMACHINE


; Banks holding data (ply 0 doubles as WHITE, and ply 1 as BLACK)


CURSOR_MOVE_SPEED               = 16
CAP_SPEED                       = 20
HOLD_DELAY                      = 40


;---------------------------------------------------------------------------------------------------


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

                    ;inc currentPly
                    ;jsr InitialiseMoveGeneration

                    PHASE AI_StepMoveGen
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
    IF 0
                    jmp SAFE_BackupBitmaps
    ENDIF
    
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

                    lda #$2
                    sta COLUP0
                    ldx #%100
                    stx CTRLPF              ; under

                    lda #0
                    sta mdelay              ;?
                    sta aiFlashPhase        ; odd/even for flashing pieces

                    lda #CAP_SPEED*2
                    sta aiFlashDelay

                    lda #-1
                    sta fromX12
                    sta toX12

                    ;lsr randomness
                    
                    PHASE AI_FlashComputerMove
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFlashComputerMove
    SUBROUTINE

                    lda squareToDraw
                    bmi .initial                    ; startup - no computer move to show

    ; "squareToDraw" is the piece that should flash while human waits

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .nodir

                    lda #1
                    sta aiFlashDelay
                    and aiFlashPhase
                    beq .initial

.nodir              dec aiFlashDelay
                    bne .exit                       ; don't flash
                    lda #CAP_SPEED*2
                    sta aiFlashDelay

                    inc aiFlashPhase

                    jsr CopySinglePiece;@0
                    rts

.initial            PHASE AI_SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSelectStartSquare

                    NEXT_RANDOM
                    
                    jsr moveCursor

    ; Search the player's movelist for the square, so we can set cursor colour
    
                    lda currentPly
                    sta SET_BANK_RAM;@2

                    lda cursorX12
                    sta fromX12

                    ldy@PLY moveIndex
                    bmi .done

.scan               cmp MoveFrom,y
                    beq .scanned
                    dey
                    bpl .scan

.scanned            lda@PLY MovePiece,y
                    sta fromPiece

.done               dec ccur                        ; pulse colour for valid squares
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

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
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

                    lda #$40

                    cpy #-1
                    beq .writeCursorCol             ; NOT in the movelist

                    lda ccur
                    lsr
                    lsr
                    lsr
                    and #3
                    clc
                    adc #$D0 ;COLOUR_LINE_1

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

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM;@2
                    lda@PLY moveIndex
                    sta aiMoveIndex
.valid

                    jsr showMoveOptions            ; draw potential moves one at a time
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

    DEF showMoveOptions
    SUBROUTINE

        REFER aiDrawMoves
        REFER aiUnDrawTargetSquares
        VAR __saveIdx, 1
        VAR __piece, 1
        VEND showMoveOptions

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)

.next               ldx aiMoveIndex
                    stx __saveIdx
                    bmi .skip

                    lda INTIM
                    cmp #2+SPEEDOF_COPYSINGLEPIECE
                    bcc .skip

                    dec aiMoveIndex

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM;@2

                    lda@PLY MoveFrom,x
                    cmp fromX12
                    bne .next

                    lda@PLY MoveTo,x
                    sta squareToDraw

                    lda@PLY MovePiece,x
                    sta __piece

    ; If it's a pawn promote (duplicate "to" AND piece different (TODO) then skip others)
    ; TODO this could/will fail on sorted lists. MMh.

                    dex
                    bmi .prom

                    lda@PLY MoveTo,x
                    cmp squareToDraw
                    bne .prom

                    lda@PLY MovePiece,x
                    eor __piece
                    and #PIECE_MASK
                    beq .prom                       ; same piece type so not a promote

                    dec aiMoveIndex
                    dec aiMoveIndex
                    dec aiMoveIndex
.prom

                    ldy squareToDraw

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    and #PIECE_MASK
                    bne .next                       ; don't draw dots on captures - they are flashed later


                    ;lda INTIM
                    ;cmp #SPEEDOF_COPYSINGLEPIECE
                    ;bcc .skip

                    ;lda aiMoveIndex
                    ;sta __saveIdx

                    jsr markerDraw;@1
                    rts

.skip               lda __saveIdx
                    sta aiMoveIndex
                    rts


;---------------------------------------------------------------------------------------------------

    DEF markerDraw
    SUBROUTINE

        REFER showMoveOptions
        VEND markerDraw

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    jsr CopySetupForMarker;@1
                    jmp InterceptMarkerCopy;@0


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

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM;@2
                    lda@PLY moveIndex
                    sta aiMoveIndex
.valid

                    jsr showMoveOptions            ; draw potential moves one at a time
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
                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM;@2
                    lda@PLY moveIndex
                    sta aiMoveIndex
.valid

                    ;lda #BANK_showMoveCaptures
                    ;sta SET_BANK;@0

                    jsr showMoveCaptures;@0
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

                    ldx #0                  ; delay

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

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda ValidSquare,y
                    cmp #-1
                    beq .invalid
                    lda __newCursor
                    sta cursorX12
.invalid

                    ldx #CURSOR_MOVE_SPEED
.cursor             stx mdelay
                    jsr setCursorPriority
.delaym             rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectDestinationSquare
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSelectDestinationSquare

    ; Piece is selected and now we're looking for a button press on a destination square
    ; we flash the piece on-and-off while we're doing that
    ; Flash the selected piece

                    lda INTIM
                    cmp #ONCEPERFRAME
                    bcc .exit


                    dec aiFlashDelay
                    bne .exit                       ; don't flash
                    lda #CAP_SPEED
                    sta aiFlashDelay

                    inc aiFlashPhase

                    jsr CopySinglePiece;@0
                    rts

.exit
                    jsr moveCursor

        lda INTIM
        cmp #20
        bcc .noButton


                    ldy cursorX12
                    sty toX12 

                    CALL GetPiece;@3
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
                    CALL GetPiece;@3                ; from the movelist

                    ldy fromX12
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    eor fromPiece
                    and #PIECE_MASK                 ; if not the same piece board/movelist...
                    bne .promote                    ; promote a pawn

                    PHASE AI_MoveIsSelected
                    rts

.promote            PHASE AI_PromotePawnStart
                    rts


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

    DEF aiMarchA2
    SUBROUTINE                    


    ; erase object in new sqare --> blank

                    ldy fromX12
                    sty squareToDraw

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    beq .skipbl
                    jsr CopySinglePiece;@0          ; erase next square along --> blank

.skipbl
                    ldy fromX12
                    sty __boardIndex

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    sta lastPiece                   ; what we are overwriting
                    lda fromPiece
                    ora #FLAG_MOVED                 ; prevents usage in castling for K/R
                    and #~FLAG_ENPASSANT
                    ldy __boardIndex
                    sta@RAM Board,y                 ; and what's actually moving there


                    PHASE AI_MarchB
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB2
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchB2

                    ldy lastSquareX12
                    sty squareToDraw

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    beq .skipbl2

                    jsr CopySinglePiece;@0          ; draw previous piece back in old position
.skipbl2

                    lda fromX12
                    cmp toX12
                    beq xhalt

                    lda #100                          ;??? inter-move segment speed (can be 0)
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


    DEF aiWriteStartPieceBlank
    SUBROUTINE

        REFER AiStateMachine
        VEND aiWriteStartPieceBlank

    ; Flash the piece in-place preparatory to moving it.
    ; drawDelay = flash speed
    ; drawCount = # of flashes

                    lda originX12
                    sta cursorX12

                    lda #%100
                    sta CTRLPF
                    lda #2
                    sta COLUP0


                    lda drawDelay
                    beq deCount
                    dec drawDelay
                    rts
deCount

                    lda drawCount
                    beq flashDone
                    dec drawCount

                    lda #READY_TO_MOVE_FLASH
                    sta drawDelay                   ; "getting ready to move" flash

                    lda fromX12
                    sta squareToDraw

                    jmp CopySinglePiece;@0          ; EOR-draw = flash

flashDone

                    PHASE AI_MarchToTargetA
                    rts


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_StateMachine"


;---------------------------------------------------------------------------------------------------

; EOF
