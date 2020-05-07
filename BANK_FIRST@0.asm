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
                    ;jsr ListPlayerMoves;@0


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
                    jsr WriteBlank;@3
                    dex
                    bpl zapem

                    lda #BANK_WriteCursor
                    sta SET_BANK
                    jsr WriteCursor;@3
    ENDIF

.notnow

.waitTime           bit TIMINT
                    bpl .waitTime

                    jmp .StartFrame


;---------------------------------------------------------------------------------------------------

    DEF ThinkBar
    SUBROUTINE

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

        REFER aiDrawEntireBoard
        REFER aiSpecialMoveFixup
        REFER aiWriteStartPieceBlank
        REFER aiDrawPart2
        REFER aiMarchB
        REFER aiFinalFlash
        REFER UNSAFE_showMoveCaptures
        REFER aiMarchToTargetA
        REFER aiMarchB2
        REFER aiMarchToTargetB
        REFER aiSelectDestinationSquare
        REFER aiPromotePawnStart
        REFER aiChoosePromotePiece
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

                    CALL CopyPieceToRowBitmap;@3
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
                    sta savedBank

                    sta SET_BANK
                    jmp (__ptr)                 ; NOTE: could branch back to squeeze cycles


;---------------------------------------------------------------------------------------------------

    DEF GenerateAllMoves
    SUBROUTINE

        REFER negaMax
        REFER quiesce
        REFER aiStepMoveGen
        REFER aiGenerateMoves
        REFER selectmove
        VAR __vector, 2
        VAR __masker, 2
        VAR __pieceFilter, 1
        VEND GenerateAllMoves

    ; Do the move generation in two passes - pawns then pieces
    ; This is an effort to get the alphabeta pruning happening with major pieces handled first in list

                    lda currentPly
                    sta SET_BANK_RAM;@2
                    jsr NewPlyInitialise
    
                    lda #8                  ; pawns
                    sta __pieceFilter
                    jsr MoveGenX
                    lda #99
                    sta currentSquare
                    lda #0
                    sta __pieceFilter
                    jsr MoveGenX

                    lda currentPly
                    sta SET_BANK_RAM
                    jmp Sort



    DEF MoveGenX
    SUBROUTINE
    
                    ldx #100
                    bne .next2

    DEF MoveReturn


                      ldx currentSquare

.next2              lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3

.next               dex
                    cpx #22
                    bcc .exit

                    lda Board,x
                    beq .next
                    cmp #-1
                    beq .next
                    eor sideToMove
                    bmi .next
                    
;    DEF handleIt
;    SUBROUTINE


                    stx currentSquare

                    eor sideToMove
                    and #~FLAG_CASTLE               ; todo: better part of the move, mmh?
                    sta currentPiece
                    and #PIECE_MASK
                    ora __pieceFilter
                    tay

                    lda HandlerVectorHI,y
                    sta __vector+1                    
                    lda HandlerVectorLO,y
                    sta __vector

                    lda HandlerVectorBANK,y
                    sta SET_BANK;@1

                    jmp (__vector)



.exit
                    rts

 
;---------------------------------------------------------------------------------------------------

    DEF ListPlayerMoves
    SUBROUTINE


                    lda #0
                    sta __quiesceCapOnly                ; gen ALL moves

                    lda #RAMBANK_PLY+1
                    sta currentPly
                    jsr GenerateAllMoves

                    ldx@PLY moveIndex
.scan               stx@PLY movePtr

                    jsr MakeMove

                    inc currentPly
                    jsr GenerateAllMoves

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    jsr unmakeMove

                    lda flagCheck
                    beq .next

                    ldx@PLY movePtr
                    lda #0
                    sta@PLY MoveFrom,x              ; invalidate move (still in check!)

.next               ldx@PLY movePtr
                    dex
                    bpl .scan

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
