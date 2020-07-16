;---------------------------------------------------------------------------------------------------
; @1 STATE MACHINE #1.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 1
    ROMBANK STATEMACHINE


; Banks holding data (ply 0 doubles as WHITE, and ply 1 as BLACK)


CURSOR_MOVE_SPEED               = 16
CAP_SPEED                       = 20
HOLD_DELAY                      = 40


;---------------------------------------------------------------------------------------------------

    DEF aiStartMoveGen
    SUBROUTINE

        REF AiStateMachine
        VEND aiStartMoveGen

    ; To assist with castling, generate the moves for the opponent, giving us effectively
    ; a list of squares that are being attacked. The castling can't happen if the king is
    ; in check or if the squares it would have to move over are in check

    ; we don't need to worry about this if K has moved, or relevant R has moved or if
    ; the squares between are occupied. We can tell THAT by examining the movelist to see
    ; if there are K-moves marked "FLAG_CASTLE" - and the relevant squares

                    ;inc currentPly
                    ;jsr InitialiseMoveGeneration

                    PHASE StepMoveGen
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiInCheckBackupStart
    SUBROUTINE

        REF AiStateMachine
        VEND aiInCheckBackupStart



                    lda #8
                    sta drawCount                   ; row to draw

                    PHASE InCheckBackup
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiInCheckBackup
    SUBROUTINE

        REF AiStateMachine
        VEND aiInCheckBackup


    ; We're about to draw some large text on the screen
    ; Make a backup copy of all of the row bitmaps, so that we can restore once text is done

                    dec drawCount
                    bmi .exit                       ; done all rows

                    JUMP BackupBitmaps;@3
    
.exit

                    lda #8
                    sta drawCount                   ; ROW

                    PHASE MaskBitmapBackground
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiWaitBitmap
    SUBROUTINE

        REF AiStateMachine
        VEND aiWaitBitmap

;                    lda INPT4
;                    bmi .noButton
    ;PHASE DrawBitmap
    ;rts
                    dec drawCount
                    lda drawCount
                    cmp #220
                    bne .noButton


.button
                    lda #8
                    sta drawCount                   ; ROW#
                    
                    PHASE RestoreBitmaps
.noButton           rts


;---------------------------------------------------------------------------------------------------

    DEF aiRestoreBitmaps
    SUBROUTINE

                    dec drawCount
                    bmi .exit                       ; done all rows

                    JUMP RestoreBitmaps;@3
    
.exit

                    lda INPT4
                    ;bmi .noButton
                    PHASE SelectStartSquare
                    rts
.noButton
;                    PHASE InCheckDelay
           PHASE SelectStartSquare
           ;PHASE InCheckBackupStart
                    rts



;---------------------------------------------------------------------------------------------------

    DEF aiInCheckDelay
    SUBROUTINE

        REF AiStateMachine
        VEND aiInCheckDelay

                    dec mdelay
                    bne .exit

                    lda #0
                    sta COLUBK

                    PHASE BeginSelectMovePhase
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiBeginSelectMovePhase
    SUBROUTINE

        REF AiStateMachine
        VEND aiBeginSelectMovePhase

                    ldx platform
                    lda greyCol,x
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

                    
                    PHASE FlashComputerMove
                    rts

greyCol
    .byte 6, 8

;---------------------------------------------------------------------------------------------------

    DEF aiFlashComputerMove
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiFlashComputerMove

                    lda squareToDraw
                    bmi .initial2                    ; startup - no computer move to show

                    lda aiFlashPhase
                    lsr
                    bcs .noSwapside                 ; only check for SELECT/exit if piece is drawn

                    lda SWCHB
                    and #SELECT_SWITCH
                    bne .noSwapside

                    PHASE DebounceSelect
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
.initial2


    ;PHASE InCheckBackupStart ;tmp
    ;rts


           PHASE SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectStartSquare
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE StartSquareSelected

.exit               rts



.swapside

                    PHASE DebounceSelect
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

                    PHASE ComputerMove  
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawMoves
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE ShowMoveCaptures
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

                    PHASE SelectDestinationSquare

.unsure             rts


;---------------------------------------------------------------------------------------------------

    DEF showMoveOptions
    SUBROUTINE

        REF aiDrawMoves
        REF aiUnDrawTargetSquares

        VAR __saveIdx, 1
        VAR __piece, 1
        
        VEND showMoveOptions

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)

.next               ldx aiMoveIndex
                    stx __saveIdx
                    bmi .skip

                    lda INTIM
                    cmp #2+SPEEDOF_CopySinglePiece
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
                    ;cmp #SPEEDOF_CopySinglePiece
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

        REF showMoveOptions
        REF showPromoteOptions

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

        REF AiStateMachine
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

                    PHASE SelectStartSquare

.exit               rts


;---------------------------------------------------------------------------------------------------


    DEF aiShowMoveCaptures
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE SlowFlash

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiSlowFlash
    SUBROUTINE

        REF AiStateMachine
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

                    PHASE ShowMoveCaptures       ; go back and rEORdraw all captures again

.slowWait           rts


.butpress           lda #1
                    sta mdelay

                    PHASE UnDrawTargetSquares
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiSelectDestinationSquare
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
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


.doCancel           PHASE ReselectDebounce
                    rts

.done               PHASE Quiescent              ; destination selected!
.noButton           rts





;---------------------------------------------------------------------------------------------------

    DEF aiRollPromotionPiece
    SUBROUTINE

        REF AiStateMachine
        VEND aiRollPromotionPiece

    ; Flash the '?' and wait for an UDLR move

                    lda INTIM
                    cmp #SPEEDOF_CopySinglePiece
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

                    PHASE ChooseDebounce
                    rts


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REF aiRollPromotionPiece ;✅
        REF aiChoosePromotePiece ;✅
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

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiChoosePromotePiece

    ; Question-mark phase has exited via joystick direction
    ; Now we cycle through the selectable pieces

                    lda INTIM
                    cmp #SPEEDOF_CopySinglePiece
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

                    PHASE ChooseDebounce         ; after draw, wait for release

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

.nothing            PHASE MoveIsSelected
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

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
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


                    PHASE MarchB
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB2
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
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
                    PHASE MarchToTargetA

                    rts

xhalt               PHASE EPHandler
                    rts




;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
; EOF
