

    NEWBANK STATEMACHINE

;    MAC PHASE ;#
;    lda #{1}
;    sta aiPhase
;    ENDM

; Banks holding data (ply 0 doubles as WHITE, and ply 1 as BLACK)

PLAYER              = RAMBANK_PLY
OPPONENT            = PLAYER + 1

CURSOR_MOVE_SPEED               = 8

;---------------------------------------------------------------------------------------------------

STARTSELECTPIECE = 1

AI_BeginSelectMovePhase         = 0
AI_SelectStartSquare            = 1
AI_StartSquareSelected          = 2
AI_DrawMoves                    = 3
AI_ShowMoveCaptures             = 4
AI_SlowFlash                    = 5
AI_DrawTargetSquares            = 6
AI_SelectDestinationSquare      = 7
AI_Quiescent                    = 8
AI_Halt                         = 9
AI_ReselectDebounce             = 10
AI_StartMoveGen                 = 11
AI_StepMoveGen                  = 12
AI_LookForCheck                 = 13
AI_StartClearBoard              = 14
AI_ClearEachRow                 = 15
AI_DrawEntireBoard              = 16
AI_DEB2                         = 17
AI_FlipBuffers                  = 18
AI_FB0                          = 19
AI_FB2                          = 20
AI_FB3                          = 21
AI_EraseStartPiece              = 22
AI_WriteStartPieceBlank         = 23
AI_MarchToTargetA               = 24
AI_MarchB                       = 25
AI_MarchToTargetB               = 26
AI_MarchB2                      = 27
AI_FinalFlash                   = 28
AI_SpecialMoveFixup             = 29
AI_InCheckBackup                = 30
AI_InCheckDelay                 = 31
AI_PromotePawnStart             = 32
AI_RollPromotionPiece           = 33
AI_ChoosePromotePiece           = 34
AI_ChooseDebounce               = 35

    DEF AiVectorLO

                    .byte <aiBeginSelectMovePhase           ; 0
                    .byte <aiSelectStartSquare              ; 1
                    .byte <aiStartSquareSelected            ; 2
                    .byte <aiDrawMoves                      ; 3
                    .byte <aiShowMoveCaptures               ; 4
                    .byte <aiSlowFlash                      ; 5
                    .byte <aiDrawTargetSquares              ; 6
                    .byte <aiSelectDestinationSquare        ; 7
                    .byte <aiQuiescent                      ; 8
                    .byte <aiHalt                           ; 9
                    .byte <aiReselectDebounce               ; 10
                    .byte <aiStartMoveGen                   ; 11
                    .byte <aiStepMoveGen                    ; 12
                    .byte <aiLookForCheck                   ; 13
                    .byte <aiStartClearBoard                ; 14
                    .byte <aiClearEachRow                   ; 15
                    .byte <aiDrawEntireBoard                ; 16
                    .byte <aiDEB2                           ; 17
                    .byte <aiFlipBuffers                    ; 18
                    .byte <aiFB0                            ; 19
                    .byte <aiFB2                            ; 20
                    .byte <aiFB3                            ; 21
                    .byte <aiEraseStartPiece                ; 22
                    .byte <aiWriteStartPieceBlank           ; 23
                    .byte <aiMarchToTargetA                 ; 24
                    .byte <aiMarchB                         ; 25
                    .byte <aiMarchToTargetB                 ; 26
                    .byte <aiMarchB2                        ; 27
                    .byte <aiFinalFlash                     ; 28
                    .byte <aiSpecialMoveFixup               ; 29
                    .byte <aiInCheckBackup                  ; 30
                    .byte <aiInCheckDelay                   ; 31
                    .byte <aiPromotePawnStart               ; 32
                    .byte <aiRollPromotionPiece             ; 33
                    .byte <aiChoosePromotePiece             ; 34
                    .byte <aiChooseDebounce                 ; 35


    DEF AiVectorHI
                    .byte >aiBeginSelectMovePhase           ; 0
                    .byte >aiSelectStartSquare              ; 1
                    .byte >aiStartSquareSelected            ; 2
                    .byte >aiDrawMoves                      ; 3
                    .byte >aiShowMoveCaptures               ; 4
                    .byte >aiSlowFlash                      ; 5
                    .byte >aiDrawTargetSquares              ; 6
                    .byte >aiSelectDestinationSquare        ; 7
                    .byte >aiQuiescent                      ; 8
                    .byte >aiHalt                           ; 9
                    .byte >aiReselectDebounce               ; 10
                    .byte >aiStartMoveGen                   ; 11
                    .byte >aiStepMoveGen                    ; 12
                    .byte >aiLookForCheck                   ; 13
                    .byte >aiStartClearBoard                ; 14
                    .byte >aiClearEachRow                   ; 15
                    .byte >aiDrawEntireBoard                ; 16
                    .byte >aiDEB2                           ; 17
                    .byte >aiFlipBuffers                    ; 18
                    .byte >aiFB0                            ; 19
                    .byte >aiFB2                            ; 20
                    .byte >aiFB3                            ; 21
                    .byte >aiEraseStartPiece                ; 22
                    .byte >aiWriteStartPieceBlank           ; 23
                    .byte >aiMarchToTargetA                 ; 24
                    .byte >aiMarchB                         ; 25
                    .byte >aiMarchToTargetB                 ; 26
                    .byte >aiMarchB2                        ; 27
                    .byte >aiFinalFlash                     ; 28
                    .byte >aiSpecialMoveFixup               ; 29
                    .byte >aiInCheckBackup                  ; 30
                    .byte >aiInCheckDelay                   ; 31
                    .byte >aiPromotePawnStart               ; 32
                    .byte >aiRollPromotionPiece             ; 33
                    .byte >aiChoosePromotePiece             ; 34
                    .byte >aiChooseDebounce                 ; 35


    DEF AiVectorBANK
                    .byte BANK_aiBeginSelectMovePhase       ; 0
                    .byte BANK_aiSelectStartSquare          ; 1
                    .byte BANK_aiStartSquareSelected        ; 2
                    .byte BANK_aiDrawMoves                  ; 3
                    .byte BANK_aiShowMoveCaptures           ; 4
                    .byte BANK_aiSlowFlash                  ; 5
                    .byte BANK_aiDrawTargetSquares          ; 6
                    .byte BANK_aiSelectDestinationSquare    ; 7
                    .byte BANK_aiQuiescent                  ; 8
                    .byte BANK_aiHalt                       ; 9
                    .byte BANK_aiReselectDebounce           ; 10
                    .byte BANK_aiStartMoveGen               ; 11
                    .byte BANK_aiStepMoveGen                ; 12
                    .byte BANK_aiLookForCheck               ; 13
                    .byte BANK_aiStartClearBoard            ; 14
                    .byte BANK_aiClearEachRow               ; 15
                    .byte BANK_aiDrawEntireBoard            ; 16
                    .byte BANK_aiDEB2                       ; 17
                    .byte BANK_aiFlipBuffers                ; 18
                    .byte BANK_aiFB0                        ; 19
                    .byte BANK_aiFB2                        ; 20
                    .byte BANK_aiFB3                        ; 21
                    .byte BANK_aiEraseStartPiece            ; 22
                    .byte BANK_aiWriteStartPieceBlank       ; 23
                    .byte BANK_aiMarchToTargetA             ; 24
                    .byte BANK_aiMarchB                     ; 25
                    .byte BANK_aiMarchToTargetB             ; 26
                    .byte BANK_aiMarchB2                    ; 27
                    .byte BANK_aiFinalFlash                 ; 28
                    .byte BANK_aiSpecialMoveFixup           ; 29
                    .byte BANK_aiInCheckBackup              ; 30
                    .byte BANK_aiInCheckDelay               ; 31
                    .byte BANK_aiPromotePawnStart           ; 32
                    .byte BANK_aiRollPromotionPiece         ; 33
                    .byte BANK_aiChoosePromotePiece         ; 34
                    .byte BANK_aiChooseDebounce             ; 35


    DEF AiTimeRequired

                    .byte 1                                  ; 0
                    .byte 40                                 ; 1
                    .byte 40                                 ; 2
                    .byte 40                                 ; 3
                    .byte 40                                 ; 4
                    .byte 40                                 ; 5
                    .byte 40                                 ; 6
                    .byte 40                                 ; 7
                    .byte 40                                 ; 8
                    .byte 40                                 ; 9
                    .byte 40                                 ; 10
                    .byte 0                                  ; 11
                    .byte 5                                  ; 12
                    .byte 40                                 ; 13
                    .byte 40                                 ; 14
                    .byte 40                                 ; 15
                    .byte 0                                  ; 16
                    .byte 40                                 ; 17
                    .byte 40                                 ; 18
                    .byte 40                                 ; 19
                    .byte 40                                 ; 20
                    .byte 40                                 ; 21
                    .byte 40                                 ; 22
                    .byte 40                                 ; 23
                    .byte 40                                 ; 24
                    .byte 40                                 ; 25
                    .byte 40                                 ; 26
                    .byte 40                                 ; 27
                    .byte 40                                 ; 28
                    .byte 40                                 ; 29
                    .byte 40                                 ; 30
                    .byte 40                                 ; 31
                    .byte 40                                 ; 32
                    .byte 40                                 ; 33
                    .byte 40                                 ; 34
                    .byte 40                                 ; 35

;---------------------------------------------------------------------------------------------------

    DEF AiSetupVectors
    SUBROUTINE

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

    DEF aiNULL
    SUBROUTINE

    ; Vectored too when not enough processing time

                    rts

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
                    jsr SAFE_InitialiseMoveGeneration

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

                    jsr SAFE_GenerateOneMove

                    lda piecelistIndex
                    and #15
                    cmp #0
                    beq .swap

                    lda INTIM
                    cmp #20
                    bcs aiStepMoveGen               ; repeat!!
                    rts


.swap               lda sideToMove
                    eor #128
                    sta sideToMove


                    PHASE AI_LookForCheck
.wait               rts


;---------------------------------------------------------------------------------------------------

    DEF aiLookForCheck
    SUBROUTINE

    jsr debug

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
                    and #3
                    clc
                    adc #$C0 ;COLOUR_LINE_1

.writeCursorCol     sta COLUP0
                    rts


    OPTIONAL_PAGEBREAK "Joystik Tables", 32

;                      RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
;                      0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111
JoyMoveX        .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   0,   0,   0
JoyMoveY        .byte     0,   0,   0,   0,   0,   1,  -1,   0,   0,   1,  -1,   0,   0,   1,  -1,   0

;---------------------------------------------------------------------------------------------------

    DEF aiStartSquareSelected
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

                    lda #6*4
                    sta ccur                            ; bright green square for selection

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

                    ;lda INTIM
                    ;cmp #10
                    ;bcs .valid


                    PHASE AI_SelectStartSquare

.exit               rts

;---------------------------------------------------------------------------------------------------

CAP_SPEED           = 8

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

                    PHASE AI_DrawTargetSquares
                    rts


;---------------------------------------------------------------------------------------------------

    DEF moveCursor
    SUBROUTINE

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

                    lda aiToSquare
                    cmp aiFromSquare                ; is to==from?  that's a cancelllation
                    beq .cancel

                    cpy #-1
                    beq .noButton                   ; not a valid square

                    lda aiFlashPhase
                    and #1
                    beq .done

    ; EOR-phase incorrect - force quick fix to allow next-frame button detect

                    lda #1
                    sta aiFlashDelay
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

                    lda #-1
                    sta highlight_row ;??? piece move error when removed...???!

                    lda aiFromSquare
                    sta fromSquare
                    lda aiToSquare
                    sta toSquare

                    lda aiFromSquareX12
                    sta fromX12
                    lda aiToSquareX12
                    sta toX12

                    jsr SAFE_GetPiece

                    lda aiPiece
                    and #PIECE_MASK
                    sta fromPiece
                    ;ora #FLAG_MOVED                ; for K/R prevents usage in castling
                    ;sta toPiece

                    ldy fromX12
                    jsr SAFE_GetPieceFromBoard

                    and #PIECE_MASK
                    cmp fromPiece
                    bne .promote


                    ldx #0
                    and #FLAG_ENPASSANT
                    beq .noep
                    ldx toX12
.noep               stx enPassantPawn               ; capturable square for en-passant move

                    PHASE AI_FB3
                    rts

.promote            PHASE AI_PromotePawnStart
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiHalt
    SUBROUTINE

    ; Effectively halt at this point until the other state machine resets the AI state machine

                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiPromotePawnStart
    SUBROUTINE

                    lda #0
                    sta aiFlashPhase
                    sta aiFlashDelay

                    ldy aiToSquare
                    sty drawPieceNumber

                    jsr SAFE_CopySinglePiece            ; remove existing piece if capture

                    PHASE AI_RollPromotionPiece
.exit               rts


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

.even
                    lda #0
                    sta aiPiece             ; cycles as index to NBRQ

                    PHASE AI_ChoosePromotePiece
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiChoosePromotePiece
    SUBROUTINE


    ; Question-mark phase has exited via joystick direction
    ; Now we cycle through the selectable pieces


                    lda INPT4
                    bmi .nobut                      ; no press

    ; button pressed but make sure phase is correct for exit

                    lda aiFlashPhase
                    and #1
                    beq .chosen                     ; button pressed --> selection made

.nobut              lda SWCHA
                    and #$F0
                    cmp #$F0
                    beq .odd                        ; no direction pressed

    ; joystick but make sure phase is correct

                    lda #0
                    sta aiFlashDelay

                    lda aiFlashPhase
                    and #1
                    bne .odd                        ; must wait until piece undrawn

    ; cycle to the next promotable piece (N/B/R/Q)
    ; TODO; use joy table for mod instead of just incrementing all the time

                    clc
                    lda aiPiece
                    adc #1
                    and #3
                    sta aiPiece

                    PHASE AI_ChooseDebounce         ; wait for release

.odd                dec aiFlashDelay
                    bpl .exit

                    lda #10
                    sta aiFlashDelay

                    inc aiFlashPhase

                    ldy aiPiece
                    ldx .promotePiece,y
                    jsr SAFE_showPromoteOptions

.exit               rts


.chosen
                    ldx aiPiece
                    lda .promoteType,x
                    sta fromPiece

                    jsr SAFE_CopySinglePiece            ; restore existing piece

                    PHASE AI_FB3
                    rts

    OPTIONAL_PAGEBREAK .promotePiece, 4
.promotePiece       .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
                    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
                    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
                    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0

    OPTIONAL_PAGEBREAK .promoteType, 4
.promoteType        .byte KNIGHT, BISHOP, ROOK, QUEEN

;---------------------------------------------------------------------------------------------------

    DEF aiChooseDebounce
    SUBROUTINE

    ; We've changed promotion piece, but wait for joystick to be released

                    lda SWCHA
                    and #$F0
                    cmp #$F0
                    bne .exit                       ; wait while joystick still pressed

                    PHASE AI_ChoosePromotePiece
.exit               rts

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
