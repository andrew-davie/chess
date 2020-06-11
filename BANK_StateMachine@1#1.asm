    SLOT 1
    ROMBANK STATEMACHINE


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


                    lda #$4
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

                    lsr randomness

                    
                    PHASE AI_FlashComputerMove
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiFlashComputerMove
    SUBROUTINE

        REFER AiStateMachine
        VEND aiFlashComputerMove

                    lda squareToDraw
                    bmi .initial2                    ; startup - no computer move to show

                    lda aiFlashPhase
                    lsr
                    bcs .noSwapside                 ; only check for SELECT/exit if piece is drawn

                    lda SWCHB
                    and #SELECT_SWITCH
                    bne .noSwapside

                    PHASE AI_DebounceSelect
                    rts
.noSwapside

    ; "squareToDraw" is the piece that should flash while human waits

                    lda SWCHA
                    and #$F0                        ; UDLR bits
                    cmp #$F0                        ; all NOT pressed
                    beq .nodir

    ; direction has been pressed, so transition out of flashing

                    lda #1
                    sta aiFlashDelay
                    and aiFlashPhase
                    beq .initial

.nodir              dec aiFlashDelay
                    bne .exit                       ; don't flash
                    lda #CAP_SPEED*2
                    sta aiFlashDelay

                    inc aiFlashPhase

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0
                    rts

.initial

                    ;SWAP
.initial2           PHASE AI_SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSelectStartSquare

                    NEXT_RANDOM

                    lda SWCHB
                    and #SELECT_SWITCH
                    beq .swapside
                    
                    CALL moveCursor;@2

    ; Search the player's movelist for the square, so we can set cursor colour
    
                    lda #RAMBANK_PLY+1 ;currentPly
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
                    CALL setCursorColours

                    tya
                    ora INPT4
                    bmi .exit                       ; illegal square or no button press

                    PHASE AI_StartSquareSelected

.exit               rts



.swapside

                    PHASE AI_DebounceSelect
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiDebounceSelect
    SUBROUTINE

                    lda SWCHB
                    and #SELECT_SWITCH
                    beq .exit                       ; SELECT still pressed

                    lda sideToMove
                    eor #HUMAN
                    sta sideToMove

                    NEGEVAL

                    PHASE AI_ComputerMove  
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawMoves

                    dec ccur
                    CALL setCursorColours

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

    ; Draw the marker..."?
    ; WARNING - local variables will not survive the following call...!

                    ldy #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    jsr CopySetupForMarker;@this
                    jmp InterceptMarkerCopy;@0



.skip               lda __saveIdx
                    sta aiMoveIndex
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopySetupForMarker
    SUBROUTINE

        REFER showMoveOptions
        REFER showPromoteOptions

        VAR __pieceColour2b, 1
        VAR __tmpb, 1
        VAR __shiftxb, 1
        
        VEND CopySetupForMarker


    ; y = base shape
    ; figure colouration of square

                    lda squareToDraw

                    ldx #10
                    sec
.sub10              sbc #10
                    dex
                    bcs .sub10
                    adc #8
                    sta __shiftxb
                    stx __tmpb
                    adc __tmpb


                    and #1
                    ;eor #1
                    beq .white
                    lda #36
.white
                    sta __pieceColour2b             ; actually SQUARE black/white

                    lda sideToMove
                    asl
                    bcc .blackAdjust
                    ora #16                         ; switch white pieces
.blackAdjust        lsr
                    and #%1111
                    tax

                    lda __shiftxb
                    and #3                          ; shift position in P
                    sta __shiftxb

                    tya
                    clc
                    adc __shiftxb
                    clc
                    adc __pieceColour2b
                    tay
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiUnDrawTargetSquares
    SUBROUTINE

        REFER AiStateMachine
        VEND aiUnDrawTargetSquares


                    dec ccur
                    CALL setCursorColours

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
                    CALL setCursorColours

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
                    CALL setCursorColours

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

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0
                    rts

.exit
                    CALL moveCursor;@2

        lda INTIM
        cmp #20
        bcc .noButton


                    ldy cursorX12
                    sty toX12 

                    CALL GetPiece;@3
                    CALL setCursorColours


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

.nojoy              lda aiFlashDelay
                    beq .do
                    dec aiFlashDelay
                    rts

.do
                    lda #30
                    sta aiFlashDelay                ; speed of "?" flashing


                    ldx #INDEX_WHITE_PROMOTE_on_WHITE_SQUARE_0
                    lda sideToMove
                    bpl .wtm
                    ldx #INDEX_BLACK_PROMOTE_on_WHITE_SQUARE_0
.wtm
                    jsr showPromoteOptions          ; draw the "?"

                    inc aiFlashPhase

.exit               rts


.even               lda #3                          ; QUEEN
                    sta fromPiece                   ; cycles as index to NBRQ

                    ;inc aiFlashPhase

                    ldx #INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0
                    lda sideToMove
                    bpl .blackStuff
                    ldx #INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
.blackStuff

                    jsr showPromoteOptions          ; draw the initial Q

                    PHASE AI_ChooseDebounce
                    rts


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REFER aiRollPromotionPiece ;✅
        REFER aiChoosePromotePiece ;✅
        VEND showPromoteOptions

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    txa
                    tay

                    jsr CopySetupForMarker;@this
                    jmp InterceptMarkerCopy;@0


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

                    lda #1
                    sta aiFlashDelay                ; force quick rehash to this if phase incorrect

                    lda aiFlashPhase
                    and #1
                    beq .chosen                     ; button pressed --> selection made
.nobut

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .nodir                      ; no direction pressed


                    lda #1
                    sta aiFlashDelay


.nodir              dec aiFlashDelay
                    bne .exit

                    lda #30
                    sta aiFlashDelay

                    lda aiFlashPhase
                    lsr
                    bcs .odd                        ; must wait until piece undrawn

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .odd                        ; no direction pressed

                    lsr
                    lsr
                    lsr
                    lsr
                    tay


    ; cycle to the next promotable piece (N/B/R/Q)
    ; TODO; use joy table for mod instead of just incrementing all the time

                    clc
                    lda fromPiece
                    adc JoyCombined,y
                    and #3
                    sta fromPiece

                    PHASE AI_ChooseDebounce         ; after draw, wait for release

.odd

.force
                    inc aiFlashPhase                ; on/off toggle

                    ldy fromPiece
                    ldx promotePiece,y
                    jsr showPromoteOptions;@this

.exit               rts






.chosen
                    lda fromPiece
                    and #PIECE_MASK
                    tax

                    lda promoteType,x
                    sta fromPiece

                    ldy toX12
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
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

    DEF aiMarchA2
    SUBROUTINE                    

        REFER AiStateMachine
        VEND aiMarchA2

    ; erase object in new sqare --> blank

                    ldy fromX12
                    sty squareToDraw

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    beq .skipbl

    ; WARNING - local variables will not survive the following call...!
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

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0          ; draw previous piece back in old position
.skipbl2

                    lda fromX12
                    cmp toX12
                    beq xhalt

                    lda #2                          ;??? inter-move segment speed (can be 0)
                    sta drawDelay
                    PHASE AI_MarchToTargetA

                    rts

xhalt               PHASE AI_EPHandler
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

                    PHASE AI_EPFlash
                    rts


.exit
            
                    lda #4                          ; on/off count (leave undrawn)
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE AI_FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_StateMachine@1#1"


;---------------------------------------------------------------------------------------------------

; EOF
