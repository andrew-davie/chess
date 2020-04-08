; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------
;#########################################  FIXED BANK  ############################################
;---------------------------------------------------------------------------------------------------

ORIGIN              SET FIXED_BANK

                    NEWBANK THE_FIXED_BANK
                    RORG $f800

;---------------------------------------------------------------------------------------------------

    DEF Reset
    SUBROUTINE

        VEND Reset

                    sei
                    cld
                    ldx #$FF
                    txs


    ; See if we can come up with something 'random' for startup

                    ldy INTIM
                    bne .toR
                    ldy #$9A
.toR                sty rnd

                    JSROM Cart_Init
                    ;JSROM TitleScreen

                    ;JSROM ShutYourMouth

    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                    JSROM_SAFE SetupBanks

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta@RAM SELFMOD_RTS_ON_LAST_ROW

                    ;lda currentPly
                    ;sta SET_BANK_RAM
                    ;jsr NewPlyInitialise            ; must be called at the start of every new ply

                    jsr InitialisePieceSquares

                    lda #WHITE
                    sta sideToMove

    ; Now the board is "living" in RAM (along with support code) we can do stuff with it

;---------------------------------------------------------------------------------------------------

                    ;RESYNC
.StartFrame


    ; START OF FRAME

                    lda #%1110                      ; VSYNC ON
.loopVSync3         sta WSYNC
                    sta VSYNC
                    lsr
                    bne .loopVSync3                 ; branch until VYSNC has been reset

                    ldy #TIME_PART_1
                    sty TIM64T

    ; LOTS OF PROCESSING TIME - USE IT

                    ldx #0
                    stx VBLANK

                    jsr AiStateMachine

#if ASSERTS
; Catch timer expired already
;                    bit TIMINT
;.whoops             bmi .whoops
#endif


.wait               bit TIMINT
                    bpl .wait



    ; START OF VISIBLE SCANLINES

                    sta WSYNC

                    jsr _rts
                    jsr _rts
                    jsr _rts
                    jsr _rts
                    SLEEP 3

                    ldx #0
                    stx VBLANK

                    stx SET_BANK_RAM
                    jsr DrawRow                     ; draw the ENTIRE visible screen!




                    lda #0
                    sta PF0
                    sta PF1
                    sta PF2
                    sta GRP0
                    sta GRP1

                    lda #%01000010                  ; bit6 is not required
                    sta VBLANK                      ; end of screen - enter blanking


; END OF VISIBLE SCREEN
; HERE'S SOME TIME TO DO STUFF

                    lda #TIME_PART_2
                    sta TIM64T

                    JSROM GameSpeak
                    jsr AiStateMachine

                    JSROM PositionSprites



    ; "draw" sprite shapes into row banks

                    ldx #7
zapem               stx SET_BANK_RAM
                    jsr WriteBlank
                    dex
                    bpl zapem

                    jsr WriteCursor


Waitforit           bit TIMINT
                    bpl Waitforit

                    jmp .StartFrame


_rts                rts


;---------------------------------------------------------------------------------------------------

    DEF AiStateMachine
    SUBROUTINE

        REFER Reset
        VEND AiStateMachine

                    JSROM AiSetupVectors
                    ;bcs .exit                   ; not enough time
                    sta SET_BANK
                    jmp (__ptr)                 ; TODO: OR branch back to squeeze cycles

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF CallClear
    SUBROUTINE

        REFER aiClearEachRow
        VEND CallClear

        ; No transient variable dependencies/calls

                    sty SET_BANK_RAM
                    jsr ClearRowBitmap
                    rts

;---------------------------------------------------------------------------------------------------


    DEF aiDrawEntireBoard
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawEntireBoard


                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
                    bcc .exit

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy squareToDraw
                    lda ValidSquare,y
                    bmi .isablank2

                    lda Board,y
                    beq .isablank
                    pha
                    lda #BLANK
                    sta@RAM Board,y

                    jsr CopySinglePiece

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    ldy squareToDraw
                    pla
                    sta@RAM Board,y

.isablank           PHASE AI_DrawPart2
                    rts

.isablank2          PHASE AI_DrawPart3
.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF aiFlipBuffers
    SUBROUTINE

        REFER AiStateMachine
        VEND aiFlipBuffers

    ; Initialise for a new move

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise            ; zap movelist for this ply

                    PHASE AI_GenerateMoves
                    rts


;---------------------------------------------------------------------------------------------------

    DEF InitialiseMoveGeneration
    SUBROUTINE

        VEND InitialiseMoveGeneration

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF newGen
    SUBROUTINE

        REFER selectmove
        VEND newGen


        jsr NewPlyInitialise
        jsr GenerateAllMoves

;        lda savedBank
;        sta SET_BANK_RAM

        rts

    DEF aiGenerateMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiGenerateMoves
    
;                    jsr newGen
                    jsr GenerateAllMoves

    #if PVSP
        jmp .player ;tmp
    #endif

                    ldx sideToMove
                    bpl .player


.computer           PHASE AI_ComputerMove               ; computer select move
                    rts


.player             PHASE AI_StartMoveGen
.wait               rts

    DEF aiStepMoveGen
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStepMoveGen


    ; Because we're (possibly) running with the screen on, processing time is very short and
    ; we generate the opponent moves piece by piece. Time isn't really an isssue here, so
    ; this happens over multiple frames.


                    jsr GenerateAllMoves

                    lda sideToMove
                    eor #128
                    sta sideToMove

                    sec
                    lda #0
                    sbc Evaluation
                    sta Evaluation
                    lda #0
                    sbc Evaluation+1
                    sta Evaluation+1                ; -Evaluation

                    PHASE AI_LookForCheck
.wait               rts


;---------------------------------------------------------------------------------------------------


    DEF GenerateAllMoves
    SUBROUTINE

        REFER quiesce
        REFER alphaBeta
        REFER aiStepMoveGen
        REFER aiGenerateMoves
        VAR __vector, 2
        VEND GenerateAllMoves
                    

                    ldx #100
                    bne .next2

MoveReturn          ldx currentSquare

.next2              lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

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
                    ;ora #FLAG_MOVED                 ; all moves mark piece as moved!
                    sta currentPiece
                    and #PIECE_MASK
                    tay

                    lda HandlerVectorLO-1,y
                    sta __vector
                    lda HandlerVectorHI-1,y
                    sta __vector+1
                    jmp (__vector)


.exit               lda currentPly ;savedBank
                    sta SET_BANK_RAM
                    rts


    MAC HANDLEVEC
        .byte {1}Handle_WHITE_PAWN        ; 1
        .byte {1}Handle_BLACK_PAWN        ; 2
        .byte {1}Handle_KNIGHT            ; 3
        .byte {1}Handle_BISHOP            ; 4
        .byte {1}Handle_ROOK              ; 5
        .byte {1}Handle_QUEEN             ; 6
        .byte {1}Handle_KING              ; 7
    ENDM


    ALLOCATE Handlers, 15

    .byte 0     ; dummy to prevent page cross access on index 0

HandlerVectorLO     HANDLEVEC <
HandlerVectorHI     HANDLEVEC >

;---------------------------------------------------------------------------------------------------

    ;TODO...
    DEF SAFE_LookForCheck
    SUBROUTINE

                    lda currentPly
                    sta SET_BANK_RAM

                    ldy moveIndex
                    bmi .failed

.scan               ldx MoveTo,y
                    lda Board,x
                    and #PIECE_MASK
                    cmp #KING
                    beq .inCheck                    ; --> CS too
                    dey
                    bpl .scan

.failed             clc

.inCheck            lda savedBank                   ; CS or CC
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiComputerMove
    SUBROUTINE

        REFER AiStateMachine
        VEND aiComputerMove

    ; Choose one of the moves

;                    lda currentPly

    lda #RAMBANK_PLY
    sta currentPly                    
                    sta SET_BANK_RAM                ; switch in movelist
                    sta savedBank

                    lda #-1
                    cmp moveIndex
                    beq .halted                     ; no valid moves

                    ;sta fromX12
                    sta originX12
                    sta toX12

                    lda sideToMove
                    bpl .notComputer
                    

                    ;ldx #2
                    ;jsr selectmove
sorter              ;jsr Sort


                    ldx #4                          ; 3 ply search!!!
                    jsr selectmove
                    ;jsr MoveViaListAtPly

                    
.notComputer        PHASE AI_MoveIsSelected
.halted             rts


     ;---------------------------------------------------------------------------------------------------

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.

    ; First, nominate referencing subroutines so that local variables can be adjusted properly

        REFER alphaBeta
        REFER MakeMove
        REFER aiMoveIsSelected
        VAR __originalPiece, 1
        VAR __capturedPiece, 1
        VEND AdjustMaterialPositionalValue

    ; fromPiece     piece doing the move (promoted type)
    ; fromX12       current square
    ; originX12     starting square
    ; toX12         ending square


    ; get the piece types from the board

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy originX12
                    lda Board,y
                    sta __originalPiece
                    ldy toX12
                    lda Board,y
                    sta __capturedPiece

    ; {
    ;   adjust the positional value  (originX12 --> fromX12)

                    lda #BANK_AddPiecePositionValue
                    sta SET_BANK 


                    ldy toX12
                    lda fromPiece
                    jsr AddPiecePositionValue       ; add pos value for new position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same1                      ; unchanged, so skip

                    lda fromPiece                   ; new piece
                    and #PIECE_MASK
                    tay
                    jsr AddPieceMaterialValue

.same1

    ; and now the 'subtracts'

                    NEGEVAL

                    ldy originX12
                    lda __originalPiece
                    jsr AddPiecePositionValue       ; remove pos value for original position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same2                      ; unchanged, so skip

                    lda __originalPiece
                    and #PIECE_MASK
                    tay
                    jsr AddPieceMaterialValue       ; remove material for original type
.same2

                    NEGEVAL

    ; If there's a capture, we adjust the material value    

;                    lda __capturedPiece
;                    eor __originalPiece
;                    bpl .noCapture                  ; special-case capture rook castling onto king


                    lda __capturedPiece
                    and #PIECE_MASK
                    beq .noCapture
                    tay
                    jsr AddPieceMaterialValue       ; -other colour = + my colour!
.noCapture

    ; }
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE

    ; Use this to trap breakpoints in "unknown" banks. Just "jsr debug" from wherever you want
    ; to catch the code, and put a breakpoint here instead. Then step, and you're at the place
    ; you wanted to see, without knowing the bank.

                    rts


;---------------------------------------------------------------------------------------------------

    DEF EnPassantCheck
    SUBROUTINE

    ; {
    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

                    ldy enPassantPawn               ; save from previous side move

                    ldx #0                          ; (probably) NO en-passant this time
                    lda fromPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    eor fromPiece                   ; clear FLAG_ENPASSANT
                    sta fromPiece

                    ldx fromX12                     ; this IS an en-passantable opening, so record the square
.noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

    ; }


    ; Check to see if we are doing an actual en-passant capture...

    ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
    ;  as the en-passant will fail if the taking piece does not have this flag set correctly

                    ;sty originX12                   ; rqd for FixPieceList

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    ;beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece
                    rts

;---------------------------------------------------------------------------------------------------

    DEF EnPassantRemovePiece
    SUBROUTINE

        REFER SpecialBody
        VEND EnPassantRemovePiece

                    jsr DeletePiece                 ; adjust material/position evaluation

                    lda sideToMove
                    eor #128
                    asl                             ; --> C
                    lda #0
                    adc #RAMBANK_PLY                ; <-- C
                    sta SET_BANK_RAM

                    rts


;---------------------------------------------------------------------------------------------------

    DEF SpecialBody
    SUBROUTINE

        COMMON_VARS_ALPHABETA
        REFER aiSpecialMoveFixup
        VEND SpecialBody

    IF ENPASSANT_ENABLED

; TODO - enpassant borked

    ; Handle en-passant captures
    ; The (dual-use) FLAG_ENPASSANT will have been cleared if it was set for a home-rank move
    ; but if we're here and the flag is still set, then it's an actual en-passant CAPTURE and we
    ; need to do the appropriate things...

                    jsr EnPassantCheck
                    beq .notEnPassant

    ; {

    ; Here we are the aggressor and we need to take the pawn 'en passant' fashion
    ; y = the square containing the pawn to capture (i.e., previous value of 'enPassantPawn')

    ; Remove the pawn from the board and piecelist, and undraw

                    sty squareToDraw
                    jsr CopySinglePiece             ; undraw captured pawn

                    ldy originX12                   ; taken pawn's square

                    jsr EnPassantRemovePiece

.notEnPassant
    ; }

    ENDIF


                    lda currentPly
                    sta SET_BANK_RAM
                    jsr  CastleFixupDraw
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

        REFER AiStateMachine
        VEND aiSpecialMoveFixup

                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
                    bcs .cont
                    rts

.cont
                    PHASE AI_FlipBuffers

                    jsr SpecialBody
                    rts


;---------------------------------------------------------------------------------------------------

    DEF DeletePiece
    SUBROUTINE


    ; Based on piece square, adjust material and position value with piece deleted
    ; y = piece square

        REFER EnPassantRemovePiece
        REFER SpecialBody
        VAR __y, 1
        VAR __col, 1
        VEND DeletePiece

                    sty __y

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y                     ; piece type

                    sta __col
                    and #PIECE_MASK
                    tay

                    lda #BANK_AddPieceMaterialValue
                    sta SET_BANK
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; adding for opponent = taking

                    rts


;---------------------------------------------------------------------------------------------------

    include "Handler_PAWN.asm"

;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE
    ; =57 including call

    ; add square in y register to movelist as destination (X12 format)
    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece. ENPASSANT flag set if pawn double-moving off opening rank

                    lda currentPly                  ; 3
                    sta SET_BANK_RAM                ; 3

                    tya                             ; 2

                    ldy moveIndex                   ; 3
                    iny                             ; 2
                    sty@RAM moveIndex     ; 4

                    sta@RAM MoveTo,y      ; 5
                    tax                             ; 2 new square (for projections)

                    lda currentSquare               ; 3
                    sta@RAM MoveFrom,y    ; 5
                    lda currentPiece                ; 3
                    sta@RAM MovePiece,y   ; 5

                    lda #RAMBANK_MOVES_RAM          ; 2 TODO: NOT NEEDED IF FIXED BANK CALLED THIS
                    sta SET_BANK_RAM                ; 3
                    rts                             ; 6


;---------------------------------------------------------------------------------------------------

    DEF InitialisePieceSquares
    SUBROUTINE

        REFER Reset
        VAR __initPiece, 1
        VAR __initSquare, 1
        VAR __initListPtr, 1
        VEND InitialisePieceSquares

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    jsr InitPieceLists

                    ldx #0
                    stx enPassantPawn               ; no en-passant


    ; Now setup the board/piecelists

.fillPieceLists     lda #RAMBANK_PLY
                    sta SET_BANK_RAM

                    lda InitPieceList,x             ; colour/-1
                    beq .exit
                    sta __originalPiece             ; type

                    ldy InitPieceList+1,x           ; square
                    sty __initSquare
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda __originalPiece
                    sta@RAM Board,y

                    bpl .white
                    NEGEVAL
.white

    ; Add the material value of the piece to the evaluation

                    lda __originalPiece
                    and #PIECE_MASK
                    tay

                    JSROM AddPieceMaterialValue

                    stx __initListPtr

    ; add the positional value of the piece to the evaluation 

                    ldy __initSquare
                    lda __originalPiece

                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK
                    jsr AddPiecePositionValue



                    lda __originalPiece             ; type/colour
                    bpl .white2
                    NEGEVAL
.white2

                    ldx __initListPtr
                    inx
                    inx
                    bpl .fillPieceLists

.exit               rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF SAFE_GetKingSquare
    SUBROUTINE

        VEND SAFE_GetKingSquare
        
    ; Pass:         A = correct bank for current side (RAMBANK_PLY/+1)
    ; Return:       A = square king is on (or -1)

                    sta SET_BANK_RAM
                    jsr GetKingSquare
                    ldy savedBank
                    sty SET_BANK
                    rts
#endif

;---------------------------------------------------------------------------------------------------

    DEF GetValid
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda ValidSquare,y
                    ldy savedBank
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetBoard
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK
                    rts

    DEF GetBoardRAM
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK_RAM
                    rts

;---------------------------------------------------------------------------------------------------

    DEF PutBoard
                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    sta@RAM Board,y             ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF IsValidMoveFromSquare
    SUBROUTINE

        REFER aiSelectStartSquare
        VEND IsValidMoveFromSquare

    ; Does the square exist in the movelist?
    ; Return: y = -1 if NOT FOUND

                    lda cursorX12
                    sta fromX12

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListFromSquare

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetPiece
    SUBROUTINE

        REFER aiSelectDestinationSquare
        REFER aiQuiescent
        VEND GetPiece

    ; Retrieve the piece+flags from the movelist, given from/to squares
    ; Required as moves have different flags but same origin squares (e.g., castling)

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr GetPieceGivenFromToSquares

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------


    DEF CopyShadowROMtoRAM
    SUBROUTINE

        REFER SetupBanks
        VAR __destinationBank, 1
        VAR __sourceBank, 1
        VEND CopyShadowROMtoRAM

    ; Copy a whole 1K ROM SHADOW into a destination RAM 1K bank
    ; used to setup callable RAM code from ROM templates

    ; x = source ROM bank
    ; y = destination RAM bank (preserved)

                    stx __sourceBank

                    ldx #0
.copyPage           lda __sourceBank
                    sta SET_BANK

                    lda $F000,x
                    pha
                    lda $F100,x
                    pha
                    lda $F200,x
                    pha
                    lda $F300,x

                    sty SET_BANK_RAM

                    sta@RAM $F300,x
                    pla
                    sta@RAM $F200,x
                    pla
                    sta@RAM $F100,x
                    pla
                    sta@RAM $F000,x

                    dex
                    bne .copyPage

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE
    TIMING COPYSINGLEPIECE, (2600)

        REFER aiDrawEntireBoard
        REFER SpecialBody
        REFER aiWriteStartPieceBlank
        REFER aiDrawPart2
        REFER aiMarchB
        REFER aiFinalFlash
        REFER UNSAFE_showMoveCaptures
        REFER aiMarchToTargetA
        REFER aiMarchB2
        REFER aiMarchToTargetB
        REFER FlashPiece
        REFER aiPromotePawnStart
        REFER aiChoosePromotePiece
        VEND CopySinglePiece

    ; WARNING: CANNOT USE VAR/OVERLAY IN ANY ROUTINE CALLING THIS!!
    ; ALSO CAN'T USE IN THIS ROUTINE
    ; This routine will STOMP on those vars due to __pieceShapeBuffer occupying whole overlay
    ; @2150 max
    ; = 33 TIM64T

                    JSROM CopySetup

    DEF InterceptMarkerCopy
    SUBROUTINE


    ; Copy a piece shape (3 PF bytes wide x 24 lines) to the RAM buffer
    ; y = piece index

                    lda #BANK_PIECE_VECTOR_BANK
                    sta SET_BANK

                    lda PIECE_VECTOR_LO,y
                    sta __ptr
                    lda PIECE_VECTOR_HI,y
                    sta __ptr+1
                    lda PIECE_VECTOR_BANK,y
                    sta SET_BANK

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

                    stx SET_BANK_RAM                ; row

                    adc #8
                    cmp #4                          ; CS = right side of screen

                    jsr CopyPieceToRowBitmap

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_getMoveIndex
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    lda moveIndex
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF GoFixPieceList

                    sta SET_BANK_RAM
                    jsr FixPieceList
                    lda savedBank
                    sta SET_BANK
                    rts
#endif

;---------------------------------------------------------------------------------------------------

    DEF markerDraw
    SUBROUTINE

        REFER SAFE_showMoveOptions
        VEND markerDraw

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REFER aiRollPromotionPiece
        REFER aiChoosePromotePiece
        VEND showPromoteOptions

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF SAFE_BackupBitmaps
    SUBROUTINE

        VEND SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF Go_IsSquareUnderAttack
    SUBROUTINE

        ;REFER aiLookForCheck
        VEND Go_IsSquareUnderAttack

    ; Check if passed X12 square is in the "TO" squares in the movelist (and thus under attack)

    ; Pass:         currentPly = which movelist to check
    ;               A = X12 square to check
    ; Return:       CC = No, CS = Yes

                    ldx currentPly
                    stx SET_BANK_RAM
                    jsr IsSquareUnderAttack
                    lda savedBank
                    sta SET_BANK
                    rts
#endif

;---------------------------------------------------------------------------------------------------

    DEF SAFE_showMoveCaptures
    SUBROUTINE

        VEND SAFE_showMoveCaptures

                    JSROM UNSAFE_showMoveCaptures
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetMoveFrom
                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda MoveFrom,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetMoveTo
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda MoveTo,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetMovePiece
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda MovePiece,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF MakeMove
    SUBROUTINE

        REFER quiesce
        REFER alphaBeta
        VAR __capture,1
        VEND MakeMove

    ; Do a move without any GUI stuff
    ; This function is ALWAYS paired with "unmake_move" - a call to both will leave board
    ; and all relevant flags in original state. This is NOT used for the visible move on the
    ; screen.


    ; fromPiece     piece doing the move
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12


    ; There are potentially "two" moves, with the following
    ; a) Castling, moving both rook and king
    ; b) en-Passant, capturing pawn on "odd" square
    ; These both set "secondary" movers which are used for restoring during unmake_move

                    lda #0
                    sta@RAM secondaryPiece



                    ldx movePtr
                    ;lda SortedMove,x
                    ;tax

                    lda MoveFrom,x
                    sta fromX12
                    sta originX12
                    lda MoveTo,x
                    sta toX12
                    lda MovePiece,x
                    sta fromPiece

.move               jsr AdjustMaterialPositionalValue

    ; Modify the board
    
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy originX12
                    lda #0
                    sta@RAM Board,y
                    ldy toX12
                    lda Board,y
                    sta __capture
                    lda fromPiece
                    and #PIECE_MASK|FLAG_COLOUR
                    ora #FLAG_MOVED
                    sta@RAM Board,y

                    lda currentPly
                    sta SET_BANK_RAM
                    lda __capture
                    sta@RAM capturedPiece

    IF CASTLING_ENABLED

        ; If the FROM piece has the castle bit set (i.e., it's a king that's just moved 2 squares)
        ; then we find the appropriate ROOK, set the secondary piece "undo" information, and then
        ; redo the moving code (for the rook, this time).

                    jsr GenCastleMoveForRook
                    bcs .move                       ; move the rook!
    ENDIF


    IF ENPASSANT_ENABLED
    
        ; TODO : piecelist

                    JSROM EnPassantCheck
                    beq .notEnPassant
                    jsr EnPassantRemovePiece        ; y = origin X12
.notEnPassant
    ENDIF


                    ;jsr FinaliseMove

    ; Swap over sides

                    sec
                    lda #0
                    sbc Evaluation
                    sta Evaluation
                    lda #0
                    sbc Evaluation+1
                    sta Evaluation+1                ; -Evaluation

                    lda sideToMove
                    eor #128
                    sta sideToMove

                    rts


;---------------------------------------------------------------------------------------------------

    DEF unmake_move
    SUBROUTINE

        REFER quiesce
        REFER alphaBeta
        VAR __unmake_capture, 1
        VAR __secondaryBlank, 1
        VEND unmake_move

    ; restore the board evaluation to what it was at the start of this ply
    ; TODO: note: moved flag seems wrong on restoration

                    lda SavedEvaluation
                    sta Evaluation
                    lda SavedEvaluation+1
                    sta Evaluation+1


                    ldx movePtr
                    ;lda SortedMove,x
                    ;tax

                    lda MoveFrom,x
                    sta fromX12
                    sta originX12
                    lda MoveTo,x
                    sta toX12
                    lda MovePiece,x
                    sta fromPiece

                    lda capturedPiece


    ; Modify the board (and the piecelists)

                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM

                    ldy toX12
                    sta@RAM Board,y

                    ldy fromX12
                    lda fromPiece
                    sta@RAM Board,y


                    lda currentPly
                    sta SET_BANK_RAM

    ; See if there are any 'secondary' pieces that moved
    ; here we're dealing with reverting a castling or enPassant move

                    lda secondaryPiece
                    beq .noSecondary
                    ldy secondaryBlank
                    sty __secondaryBlank
                    ldy secondarySquare


                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    sta@RAM Board,y                     ; put piece back

                    ldy __secondaryBlank
                    lda #0
                    sta@RAM Board,y                     ; blank piece origin

                    lda currentPly
                    sta SET_BANK_RAM


.noSecondary
                    lda sideToMove
                    eor #128
                    sta sideToMove

                    rts


;---------------------------------------------------------------------------------------------------

;def quiesce( alpha, beta ):
;    stand_pat = evaluate_board()
;    if( stand_pat >= beta ):
;        return beta
;    if( alpha < stand_pat ):
;        alpha = stand_pat
;
;    for move in board.legal_moves:
;        if board.is_capture(move):
;            make_move(move)
;            score = -quiesce( -beta, -alpha )
;            unmake_move()
;            if( score >= beta ):
;                return beta
;            if( score > alpha ):
;                alpha = score
;    return alpha


    DEF quiesce
    SUBROUTINE

    ; We are at the lowest level of the tree search, so we want to only continue if there
    ; are captures in effect. Keep going until there are no captures.

    ; requriement: correct PLY bank already switched in
    ; --> savedBank too

        COMMON_VARS_ALPHABETA
        REFER alphaBeta
        VEND quiesce

#if 0
    ; we have already done the Evaluation (incrementally)

    ; setup parameters
    ; beta = -alpha, alpha = -beta

                    lda __beta
                    sta@RAM alpha
                    lda __beta+1
                    sta@RAM alpha+1

                    lda __alpha
                    sta@RAM beta
                    lda __alpha+1
                    sta@RAM beta+1

    DEF QuiesceStart



;def quiesce( alpha, beta ):
;    stand_pat = evaluate_board()
;    if( stand_pat >= beta ):
;        return beta
;    if( alpha < stand_pat ):
;        alpha = stand_pat
;
;    for move in board.legal_moves:
;        if board.is_capture(move):
;            make_move(move)
;            score = -quiesce( -beta, -alpha )
;            unmake_move()
;            if( score >= beta ):
;                return beta
;            if( score > alpha ):
;                alpha = score
;    return alpha



;    if( stand_pat >= beta ):
;        return beta

                    sec
                    lda Evaluation
                    sbc beta
                    lda Evaluation+1
                    sbc beta+1
                    bvc .lab0                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab0               bmi .endif0

;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.

                    lda beta+1
                    sta __bestScore+1
                    lda beta
                    sta __bestScore
                    rts
.endif0

;    if( alpha < stand_pat ):
;        alpha = stand_pat

                    clc                             ;!! OK
                    lda alpha
                    sbc Evaluation
                    lda alpha+1
                    sbc Evaluation+1
                    bvc .lab1                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab1               bpl .endif1

;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.


                    lda Evaluation
                    sta@RAM alpha
                    lda Evaluation+1
                    sta@RAM alpha+1

.endif1

    lda currentPly
    sta savedBank



                    jsr newGen

                    lda moveIndex
                    sta@RAM movePtr

.loopMoves

                    ;lda currentPly
                    ;sta SET_BANK_RAM



                    ldx movePtr
                    bpl .cont

    ; finished looking, all moves done - return alpha

                    lda alpha
                    sta __bestScore
                    lda alpha+1
                    sta __bestScore+1
                    rts

.cont




    ;        if board.is_capture(move):
    ;            make_move(move)

                    ldy MoveTo,x

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    ldx currentPly
                    stx SET_BANK_RAM
                    and #PIECE_MASK
                    beq .nextMove                   ; only process capture moves

        lda currentPly
        sta SET_BANK_RAM

                    jsr MakeMove

    ; TODO: can't go past MAX_PLY... thing

    ; score = -quiesce( -beta, -alpha )

                    sec
                    lda #0
                    sbc beta
                    sta __beta
                    lda #0
                    sbc beta+1
                    sta __beta+1                    ; -beta

                    sec
                    lda #0
                    sbc alpha
                    sta __alpha
                    lda #0
                    sbc alpha+1
                    sta __alpha+1                   ; -alpha

                    inc currentPly
                    ldx currentPly
                    stx SET_BANK_RAM

                    jsr quiesce                     ; recurse

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    sec
                    lda #0
                    sbc __bestScore
                    sta __bestScore
                    lda #0
                    sbc __bestScore+1
                    sta __bestScore+1               ; "-quiesce(..."

                    jsr unmake_move


;def quiesce( alpha, beta ):
;    stand_pat = evaluate_board()
;    if( stand_pat >= beta ):
;        return beta
;    if( alpha < stand_pat ):
;        alpha = stand_pat
;
;    for move in board.legal_moves:
;        if board.is_capture(move):
;            make_move(move)
;            score = -quiesce( -beta, -alpha )
;            unmake_move()
;            if( score >= beta ):
;                return beta
;            if( score > alpha ):
;                alpha = score
;    return alpha


;            if( score >= beta ):
;                return beta

                    sec
                    lda __bestScore
                    sbc beta
                    lda __bestScore+1
                    sbc beta+1
                    bvc .lab2                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab2               bmi .endif2

;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.

                    lda beta
                    sta __bestScore
                    lda beta+1
                    sta __bestScore+1
                    rts

.endif2

;            if( score > alpha ):
;                alpha = score

                    clc                             ; !! OK
                    lda alpha
                    sbc __bestScore
                    lda alpha+1
                    sbc __bestScore+1
                    bvc .lab3                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab3               bpl .endif3

;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.

                    lda __bestScore
                    sta@RAM alpha
                    lda __bestScore+1
                    sta@RAM alpha+1
.endif3


    ; end of move iteration/loop

.nextMove           sec
                    lda movePtr
                    sbc #1
                    sta@RAM movePtr
                    jmp .loopMoves
#endif

;---------------------------------------------------------------------------------------------------

    SUBROUTINE

.terminal           ;jsr QuiesceStart                ; with alpha, beta already setup
;                    rts

                    lda Evaluation
                    sta __bestScore
                    lda Evaluation+1
                    sta __bestScore+1

#if 0
    lda moveIndex
    bmi .OF

    sec
    lda __bestScore
    sbc moveIndex
    sta __bestScore
    lda __bestScore+1
    sbc #0
    sta __bestScore+1
    rts



.OF
#endif
                    rts


.returnScore

    ; we've iterated the moves, so 'bestMove' and 'bestScore' are the result

                    lda bestScore
                    sta __bestScore
                    lda bestScore+1
                    sta __bestScore+1               ; value of the best move found

                    lda bestMove
                    sta __bestMove                  ; moveIndex of the best move found
                    rts


    DEF alphaBeta

    ; Performs an alpha-beta search.
    ; The current 'level' is always considered in terms of maximising the evaluation
    ; To achieve minimisation for the opponent when being considered, the alpha/beta are negated
    ; and which is which is swapped between each ply

    ; pass...
    ; x = depthleft
    ; SET_BANK_RAM      --> current ply
    ; __alpha[2] = -alpha
    ; __beta[2] = -beta


        COMMON_VARS_ALPHABETA
        REFER selectmove
        VEND alphaBeta


    ;def alphabeta( alpha, beta, depthleft ):
    ;    bestscore = -9999
    ;    if( depthleft == 0 ):
    ;        return quiesce( alpha, beta )
    ;    for move in board.legal_moves:
    ;        make_move(move)
    ;        score = -alphabeta( -beta, -alpha, depthleft - 1 )
    ;        unmake_move()
    ;        if( score >= beta ):
    ;            return score
    ;        if( score > bestscore ):
    ;            bestscore = score
    ;        if( score > alpha ):
    ;            alpha = score
    ;    return bestscore

                    stx@RAM depthLeft


    ; setup parameters
    ; beta = -alpha, alpha = -beta
    ; we want to maximise alpha
    ;  and if score > beta then abort (cutoff)

                    lda __beta
                    sta@RAM alpha
                    lda __beta+1
                    sta@RAM alpha+1

                    lda __alpha
                    sta@RAM beta
                    lda __alpha+1
                    sta@RAM beta+1

    ; on 1st call this becomes alpha = -INF and beta = INF
    ; we're trying to maximise alpha

                    cpx #0
                    beq .terminal                   ; --> quiesce

                    lda #<-(INFINITY-1)
                    sta@RAM bestScore
                    lda #>-(INFINITY-1)
                    sta@RAM bestScore+1



    ; The evaluation of the current position is a signed 16-bit number
    ; +ve is good for the current side.
    ; This is used during the alpha-beta search for finding best position
    ; Note, this is not the same as the 'Evaluation' which is the current value at ply -- it is the
    ; alphabeta best/worst value of the node!!


                    jsr NewPlyInitialise
                    jsr GenerateAllMoves

                    jsr Sort

    ; Now iterate the moves one-by-one

#if 1
                    lda moveIndex
                    lsr
                    clc
                    adc SavedEvaluation
                    sta@RAM SavedEvaluation
                    lda SavedEvaluation+1
                    adc #0
                    sta@RAM SavedEvaluation+1                ; + mobility (kind of odd/bad - happens every level)
#endif

                    lda moveIndex
                    sta@RAM movePtr


.loopMoves          ldx movePtr
                    bmi .returnScore
                    ;lda SortedMove,x
                    ;tax

                    jsr MakeMove

    ; "score = -alphabeta( -beta, -alpha, depthleft - 1 )"
    ; set pareameters for next level --> __alpha, __beta
    
                    sec
                    lda #0
                    sbc alpha
                    sta __alpha
                    lda #0
                    sbc alpha+1
                    sta __alpha+1                   ; -alpha

                    sec
                    lda #0
                    sbc beta
                    sta __beta
                    lda #0
                    sbc beta+1
                    sta __beta+1                    ; -beta

                    ldx depthLeft
                    dex

                    inc currentPly
                    lda currentPly
                    sta SET_BANK_RAM                ; self-switch

                    jsr alphaBeta                   ; recurse!

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    sec
                    lda #0
                    sbc __bestScore
                    sta __bestScore
                    lda #0
                    sbc __bestScore+1
                    sta __bestScore+1               ; "-alphabeta....""

                    jsr unmake_move

                    ldx movePtr
                    ;lda SortedMove,x
                    ;tax

                    lda __bestScore
                    sta@RAM MoveScoreLO,x
                    lda __bestScore+1
                    sta@RAM MoveScoreHI,x


    ;        if( score >= beta ):
    ;            return score

    ; an alpha-beta cutoff?
    ; aborts searching any more moves because the opponent score improves

                    sec                             ; drop for extra speed
                    lda __bestScore
                    sbc beta
                    lda __bestScore+1
                    sbc beta+1
                    bvc .lab2                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab2               bmi .notScoreGteBeta            ; A < NUM

                    lda bestMove
                    sta __bestMove                  ; this move!
                    rts

.notScoreGteBeta

    ;        if( score > bestscore ):
    ;            bestscore = score

                    clc                             ; !! OK. Could be dropped for a bit of speed
                    lda __bestScore
                    sbc bestScore
                    lda __bestScore+1
                    sbc bestScore+1
                    bvc .lab3                       ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                        ; A = A eor $80, and N= N eor 1
.lab3               bmi .notScoreGtBestScore        ; A < NUM

                    lda __bestScore
                    sta@RAM bestScore
                    lda __bestScore+1
                    sta@RAM bestScore+1

                    ;ldx movePtr
                    ;lda SortedMove,x
                    lda movePtr
                    sta@RAM bestMove

.notScoreGtBestScore


    ;        if( score > alpha ):
    ;            alpha = score

    ; We've found a higher scoring move than currently known, so record it

                    clc                     ; !! OK. Could be dropped for a bit of speed
                    lda alpha
                    sbc __bestScore
                    lda alpha+1
                    sbc __bestScore+1
                    bvc .lab                ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
                    eor #$80                ; A = A eor $80, and N= N eor 1
.lab                bpl .notScoreGtAlpha    ; A >= NUM

                    lda __bestScore
                    sta@RAM alpha
                    lda __bestScore+1
                    sta@RAM alpha+1

.notScoreGtAlpha    ldx movePtr
                    dex
                    stx@RAM movePtr
                    jmp .loopMoves


;---------------------------------------------------------------------------------------------------

    ECHO "FREE BYTES IN FIXED BANK = ", $FFFC - *

;---------------------------------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the fixed bank (last 2K of any ROM image in "3E" scheme)

    SEG InterruptVectors
    ORG FIXED_BANK + $7FC
    RORG $7ffC

                    .word Reset                     ; RESET
                    .word Reset                     ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
; EOF
