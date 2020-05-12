; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


; SLOT0 - screen draw, state machine dispatcher
; SLOT1 - anything
; SLOT2 - moves/ply
; SLOT3 - board






    SLOT 0

;---------------------------------------------------------------------------------------------------
;#########################################  FIXED BANK  ############################################
;---------------------------------------------------------------------------------------------------

_ORIGIN             SET _FIRST_BANK

                    NEWBANK THE_FIRST_BANK
                    RORG $f000

;---------------------------------------------------------------------------------------------------

    DEF StartupBankReset
    SUBROUTINE

        VEND StartupBankReset

    ; On startup, 3E+ switches banks 0 and 3 to the 1st ROM bank (1K), from which the reset
    ; vector is obtained from bank 0 (+$FFC). Chess3E+ (maybe) will leave this bank (3) alone
    ; so that a system reset will always have the reset vectors available at FFFC, where expected

                    ldx #$FF
                    txs

                    CALL CartInit
                    CALL SetupBanks
                    CALL InitialisePieceSquares
                    jsr ListPlayerMoves;@0


.StartFrame


    ; START OF FRAME

                    lda #%1110                      ; VSYNC ON
.loopVSync3         sta WSYNC
                    sta VSYNC
                    lsr
                    bne .loopVSync3                 ; branch until VYSNC has been reset

                    sta VBLANK

                    ldy #TIME_PART_1
                    sty TIM64T

    ; LOTS OF PROCESSING TIME - USE IT



                    jsr AiStateMachine

    IF ASSERTS
; Catch timer expired already
;                    bit TIMINT
;.whoops             bmi .whoops
    ENDIF


.wait               bit TIMINT
                    bpl .wait


    ; START OF VISIBLE SCANLINES


                    CALL longD


                    ldx #SLOT_DrawRow ; + BANK_DrawRow
                    stx SET_BANK_RAM
                    jsr DrawRow                     ; draw the ENTIRE visible screen!

                    CALL tidySc

                    jsr AiStateMachine

    lda INTIM
    cmp #20
    bcc .notnow                    

                    ;CALL GameSpeak
                    CALL PositionSprites


    IF 1
    ; "draw" sprite shapes into row banks

                    ldx #7
zapem               txa
                    clc
                    adc #SLOT_DrawRow
                    sta SET_BANK_RAM
                    CALL WriteBlank;@3
                    dex
                    bpl zapem

                    lda #BANK_WriteCursor
                    sta SET_BANK
                    CALL WriteCursor;@3
    ENDIF

.notnow

.waitTime           bit TIMINT
                    bpl .waitTime

                    jmp .StartFrame


;---------------------------------------------------------------------------------------------------

    DEF ThinkBar
    SUBROUTINE

        REFER negaMax
        VEND ThinkBar

        IF DIAGNOSTICS

                    inc positionCount
                    bne .p1
                    inc positionCount+1
                    bne .p1
                    inc positionCount+2
.p1
        ENDIF

    ; The 'thinkbar' pattern...

                    lda #0
                    ldy INPT4
                    bmi .doThink
    
    DEF ThinkBarDebug
    
                    inc __thinkbar
                    lda __thinkbar
                    and #15
                    tay
                    lda SynapsePattern,y

.doThink            sta PF2
                    sta PF1
                    rts



SynapsePattern

    .byte %11000001
    .byte %01100000
    .byte %00110000
    .byte %00011000
    .byte %00001100
    .byte %00000110
    .byte %10000011
    .byte %11000001

    .byte %10000011
    .byte %00000110
    .byte %00001100
    .byte %00011000
    .byte %00110000
    .byte %01100000
    .byte %11000001
    .byte %10000011


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece;@0 - uses @2
    SUBROUTINE
    TIMING COPYSINGLEPIECE, (2600)

        REFER showMoveCaptures
        REFER aiDrawEntireBoard
        REFER aiDrawPart2
        REFER aiMarchB
        REFER aiFlashComputerMove
        REFER aiSelectDestinationSquare
        REFER aiMarchA2
        REFER aiMarchB2
        REFER aiWriteStartPieceBlank
        REFER aiChoosePromotePiece
        REFER aiMarchToTargetB
        REFER aiPromotePawnStart
        REFER aiFinalFlash

    IF ENPASSANT_ENABLED
        REFER EnPassantCheck
    ENDIF

        VEND CopySinglePiece

    ; WARNING: CANNOT USE VAR/OVERLAY IN ANY ROUTINE CALLING THIS!!
    ; ALSO CAN'T USE IN THIS ROUTINE
    ; This routine will STOMP on those vars due to __pieceShapeBuffer occupying whole overlay
    ; @2150 max
    ; = 33 TIM64T

    ; Board is [SLOT3]


                    CALL CopySetup;@2


    DEF InterceptMarkerCopy
    SUBROUTINE

        REFER CopySinglePiece
        REFER showPromoteOptions
        REFER showMoveOptions
        VEND InterceptMarkerCopy

    ; Copy a piece shape (3 PF bytes wide x 24 lines) to the RAM buffer
    ; y = piece index

                    lda #BANK_PIECE_VECTOR_BANK
                    sta SET_BANK;@2

                    lda PIECE_VECTOR_LO,y
                    sta __ptr
                    lda PIECE_VECTOR_HI,y
                    sta __ptr+1
                    lda PIECE_VECTOR_BANK,y
                    sta SET_BANK;@2

                    ldy #PIECE_SHAPE_SIZE-1
.copy               lda (__ptr),y
                    sta __pieceShapeBuffer,y
                    dey
                    bpl .copy

                    lda squareToDraw
                    sec
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    adc #8
                    cmp #4                          ; CS = right side of screen

                    txa
                    ora #[SLOT2]
                    sta SET_BANK_RAM;@2             ; bank row

                    jsr CopyPieceToRowBitmap;@3
                    rts


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
        
        {1} FlashComputerMove                       ; 0
        {1} BeginSelectMovePhase                    ; 1
        {1} SelectStartSquare                       ; 2
        {1} StartSquareSelected                     ; 3
        {1} DrawMoves                               ; 4
        {1} ShowMoveCaptures                        ; 5
        {1} SlowFlash                               ; 6
        {1} UnDrawTargetSquares                     ; 7
        {1} SelectDestinationSquare                 ; 8
        {1} Quiescent                               ; 9
        {1} ReselectDebounce                        ; 10
        {1} StartMoveGen                            ; 11
        {1} StepMoveGen                             ; 12
        {1} StartClearBoard                         ; 13
        {1} ClearEachRow                            ; 14
        {1} DrawEntireBoard                         ; 15
        {1} DrawPart2                               ; 16
        {1} DrawPart3                               ; 17
        {1} GenerateMoves                           ; 18
        {1} ComputerMove                            ; 19
        {1} MoveIsSelected                          ; 20
        {1} WriteStartPieceBlank                    ; 21
        {1} MarchToTargetA                          ; 22
        {1} MarchA2                                 ; 23
        {1} MarchB                                  ; 24
        {1} MarchToTargetB                          ; 25
        {1} MarchB2                                 ; 26
        {1} FinalFlash                              ; 27
        {1} SpecialMoveFixup                        ; 28
        {1} InCheckBackup                           ; 29
        {1} InCheckDelay                            ; 30
        {1} PromotePawnStart                        ; 31
        {1} RollPromotionPiece                      ; 32
        {1} ChoosePromotePiece                      ; 33
        {1} ChooseDebounce                          ; 34
        {1} CheckMate                               ; 35
        {1} Draw                                    ; 36
        {1} DelayAfterMove                          ; 37
        {1} DelayAfterMove2                         ; 38
        {1} DelayAfterPlaced                        ; 39
        {1} DelayAfterPlaced2                       ; 40

    ENDM

    TABDEF AIN

    DEF AiVectorLO
        TABDEF LO

    DEF AiVectorHI
        TABDEF HI

    DEF AiVectorBANK
        TABDEF BK


;---------------------------------------------------------------------------------------------------

    DEF AiStateMachine
    SUBROUTINE

        REFER StartupBankReset
        VEND AiStateMachine


    ; State machine vector setup - points to current routine to execute

                    ldx aiState
                    lda AiVectorLO,x
                    sta __ptr
                    lda AiVectorHI,x
                    sta __ptr+1

                    lda AiVectorBANK,x
                    sta SET_BANK
                    jmp (__ptr)                 ; NOTE: could branch back to squeeze cycles


;---------------------------------------------------------------------------------------------------

    DEF GenerateAllMoves
    SUBROUTINE

        REFER ListPlayerMoves
        REFER aiComputerMove
        REFER quiesce
        REFER negaMax

        VAR __vector, 2
        VAR __masker, 2
        VAR __pieceFilter, 1

        VEND GenerateAllMoves

    ; Do the move generation in two passes - pawns then pieces
    ; This is an effort to get the alphabeta pruning happening with major pieces handled first in list

    ;...
    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty
    ; x must be preserved

                    lda currentPly
                    sta SET_BANK_RAM;@2

    ; note that 'alpha' and 'beta' are set externally!!

                    lda #-1
                    sta@PLY moveIndex           ; no valid moves
                    sta@PLY bestMove

                    lda enPassantPawn               ; flag/square from last actual move made
                    sta@PLY enPassantSquare         ; used for backtracking, to reset the flag


    ; The value of the material (signed, 16-bit) is restored to the saved value at the reversion
    ; of a move. It's quicker to restore than to re-sum. So we save the current evaluation at the
    ; start of each new ply.

                    lda Evaluation
                    sta@PLY savedEvaluation
                    lda Evaluation+1
                    sta@PLY savedEvaluation+1
    ;^



                    lda #8                  ; pawns
                    sta __pieceFilter
                    jsr MoveGenX
                    lda #99
                    sta currentSquare
                    lda #0
                    sta __pieceFilter
                    jsr MoveGenX

                    lda #BANK_Sort
                    sta SET_BANK
                    jmp Sort;@1



    DEF MoveGenX
    SUBROUTINE
    
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3             ; should be hardwired forever, right?

                    ldx #100
                    bne .next

    DEF MoveReturn

                    ldx currentSquare
.next               dex
                    cpx #22
                    bcc .exit

                    lda Board,x
                    beq .next
                    cmp #-1
                    beq .next
                    eor sideToMove
                    bmi .next
                    
                    stx currentSquare

                    eor sideToMove
                    and #~FLAG_CASTLE               ; todo: better part of the move, mmh?
                    sta currentPiece
                    and #PIECE_MASK
                    ora __pieceFilter
                    tay

                    lda #BANK_HandlerVectorLO
                    sta SET_BANK

                    lda HandlerVectorHI,y
                    sta __vector+1                    
                    lda HandlerVectorLO,y
                    sta __vector

                    lda HandlerVectorBANK,y
                    sta SET_BANK;@1

                    jmp (__vector)



.exit               jmp fixBank

 
;---------------------------------------------------------------------------------------------------

    DEF ListPlayerMoves
    SUBROUTINE

        REFER selectmove
        REFER StartupBankReset

        VEND ListPlayerMoves


                    lda #0
                    sta __quiesceCapOnly                ; gen ALL moves

                    lda #RAMBANK_PLY+1
                    sta currentPly
                    
                    ;inc currentPly ;tmp
                    jsr GenerateAllMoves;@this

                    ldx@PLY moveIndex
.scan               stx@PLY movePtr


                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM

                    CALL MakeMove;@1

                    inc currentPly
                    jsr GenerateAllMoves;@this

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM;@2

                    jsr unmakeMove;@this

                    lda currentPly
                    sta SET_BANK_RAM;@2

                    lda flagCheck
                    beq .next

                    ldx@PLY movePtr
                    lda #0
                    sta@PLY MoveFrom,x              ; invalidate move (still in check!)

.next               ldx@PLY movePtr
                    dex
                    bpl .scan

                    rts

    DEF fixBank
    SUBROUTINE

                    lda #BANK_negaMax
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE

        REFER Handle_KING
        REFER Handle_QUEEN
        REFER Handle_ROOK
        REFER Handle_BISHOP
        REFER Handle_KNIGHT
        REFER Handle_WHITE_PAWN
        REFER Handle_BLACK_PAWN

        VEND AddMove

    ; add square in y register to movelist as destination (X12 format)
    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece.
    ;   ENPASSANT flag set if pawn double-moving off opening rank
    ; capture           captured piece


                    lda capture
                    bne .always
                    lda __quiesceCapOnly
                    bne .abort

.always             tya
                    tax

                    ldy@PLY moveIndex
                    iny
                    sty@PLY moveIndex
                    
                    sta@PLY MoveTo,y
                    lda currentSquare
                    sta@PLY MoveFrom,y
                    lda currentPiece
                    sta@PLY MovePiece,y
                    lda capture
                    sta@PLY MoveCapture,y
                    rts
                    
.abort              tya
                    tax
                    rts



;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE
                    rts


;---------------------------------------------------------------------------------------------------

    DEF unmakeMove
    SUBROUTINE

        REFER selectmove
        REFER ListPlayerMoves
        REFER quiesce
        REFER negaMax

        VAR __unmake_capture, 1
        VAR __secondaryBlank, 1

        VEND unmakeMove

    ; restore the board evaluation to what it was at the start of this ply
    ; TODO: note: moved flag seems wrong on restoration

                    lda currentPly
                    sta SET_BANK_RAM;@2

                    lda@PLY savedEvaluation
                    sta Evaluation
                    lda@PLY savedEvaluation+1
                    sta Evaluation+1

                    ldx movePtr
                    lda@PLY MoveFrom,x
                    sta fromX12
                    ldy@PLY MoveTo,x

                    lda@PLY restorePiece
                    pha
                    lda@PLY capturedPiece

                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM;@3
                    sta@RAM Board,y
                    ldy fromX12
                    pla
                    sta@RAM Board,y


                    ;lda currentPly
                    ;sta SET_BANK_RAM

    ; See if there are any 'secondary' pieces that moved
    ; here we're dealing with reverting a castling or enPassant move

                    lda@PLY secondaryPiece
                    beq .noSecondary
                    ldy@PLY secondaryBlank
                    sty __secondaryBlank
                    ldy@PLY secondarySquare
                    sta@RAM Board,y                     ; put piece back

                    ldy __secondaryBlank
                    lda #0
                    sta@RAM Board,y                     ; blank piece origin


.noSecondary
                    ;NEGEVAL
                    SWAP
                    rts


;---------------------------------------------------------------------------------------------------

    DEF showMoveCaptures
    SUBROUTINE

        REFER aiShowMoveCaptures

        VAR __toSquareX12, 1
        VAR __fromPiece, 1
        VAR __aiMoveIndex, 1

        VEND showMoveCaptures

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next               ldx aiMoveIndex
                    stx __aiMoveIndex
                    bmi .skip                       ; no moves in list

                    lda INTIM
                    cmp #20
                    bcc .skip

                    dec aiMoveIndex

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    lda@PLY MoveFrom,x
                    cmp fromX12
                    bne .next

                    lda@PLY MoveTo,x
                    sta __toSquareX12
                    tay

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    and #PIECE_MASK
                    beq .next

    ; There's something on the board at destination, so it's a capture
    ; Let's see if we are doing a pawn promote...

                    ldy fromX12

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    sta __fromPiece

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    lda@PLY MovePiece,x
                    eor __fromPiece
                    and #PIECE_MASK
                    beq .legit                  ; from == to, so not a promote

    ; Have detected a promotion duplicate - skip all 3 of them

                    dec aiMoveIndex                 ; skip "KBRQ" promotes
                    dec aiMoveIndex
                    dec aiMoveIndex

.legit

        ;TIMECHECK COPYSINGLEPIECE, restoreIndex     ; not enough time to draw

                    lda __toSquareX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0

.skip               rts


;---------------------------------------------------------------------------------------------------

    DEF CopyPieceToRowBitmap;@3
    SUBROUTINE

        REFER InterceptMarkerCopy
        VEND CopyPieceToRowBitmap

                    ldy #17
                    bcs .rightSide

.copyPiece          lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap,y
                    sta@RAM ChessBitmap,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+18,y
                    sta@RAM ChessBitmap+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+36,y
                    sta@RAM ChessBitmap+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+54,y
                    sta@RAM ChessBitmap+54,y

.blank4             dey
                    bpl .copyPiece
                    rts

.rightSide

    SUBROUTINE

.copyPieceR         lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap+72,y
                    sta@RAM ChessBitmap+72,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+72+18,y
                    sta@RAM ChessBitmap+72+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+72+36,y
                    sta@RAM ChessBitmap+72+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+72+54,y
                    sta@RAM ChessBitmap+72+54,y

.blank4             dey
                    bpl .copyPieceR
                    rts

;---------------------------------------------------------------------------------------------------

    ECHO "FREE BYTES IN STARTUP BANK = ", $F3FC - *

;---------------------------------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the first 1K bank of the ROM
    
    SEG StartupInterruptVectors
    ORG _FIRST_BANK + $3FC

                    .word StartupBankReset            ; RESET
                    .word StartupBankReset            ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------


; EOF
