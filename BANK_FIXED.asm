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

                    ldx #$FF
                    txs

                    JSROM_SAFE Cart_Init

                    ;JSROM TitleScreen

                    ;JSROM ShutYourMouth

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta@RAM SELFMOD_RTS_ON_LAST_ROW

                    jsr InitialisePieceSquares


                    ;RESYNC
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

#if ASSERTS
; Catch timer expired already
;                    bit TIMINT
;.whoops             bmi .whoops
#endif

.wait               bit TIMINT
                    bpl .wait


    ; START OF VISIBLE SCANLINES


                    JSROM longD

                    stx SET_BANK_RAM
                    jsr DrawRow                     ; draw the ENTIRE visible screen!

                    JSROM tidySc
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
                    sta SET_BANK
                    jmp (__ptr)                 ; TODO: OR branch back to squeeze cycles


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

                    lda #RAMBANK_BOARD
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

                    lda #RAMBANK_BOARD
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

        ;PHASE AI_ComputerMove
        ;rts

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
        jmp GenerateAllMoves

;        lda savedBank
;        sta SET_BANK_RAM

;        rts


;---------------------------------------------------------------------------------------------------

    DEF aiGenerateMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiGenerateMoves
    
;                    jsr newGen
                    jsr GenerateAllMoves

    #if PVSP
        jmp .player ;tmp
    #endif

    ;TODO -- mmh!!!!

                    ldx sideToMove
                    bpl .player


.computer           PHASE AI_ComputerMove               ; computer select move
                    rts


.player             PHASE AI_StartMoveGen
.wait               rts


;---------------------------------------------------------------------------------------------------

    DEF aiStepMoveGen
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStepMoveGen


    ; Because we're (possibly) running with the screen on, processing time is very short and
    ; we generate the opponent moves piece by piece. Time isn't really an isssue here, so
    ; this happens over multiple frames.

                    jsr GenerateAllMoves
                    PHASE AI_BeginSelectMovePhase ;LookForCheck
.wait               rts


;---------------------------------------------------------------------------------------------------


    DEF GenerateAllMoves
    SUBROUTINE

        REFER negamax
        REFER aiStepMoveGen
        REFER aiGenerateMoves
        VAR __vector, 2
        VAR __masker, 1
        VEND GenerateAllMoves


                    lda #3
                    sta __masker
                    lda #0
                    sta __masker+1
                    jsr GenMoves

                    lda #8
                    sta __masker
                    lda #3
                    sta __masker+1
                    jsr GenMoves


                    rts


    DEF GenMoves
    
                    ldx #100
                    bne .next2

MoveReturn          ldx currentSquare

.next2              lda #RAMBANK_BOARD
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
                    sta currentPiece
                    and #PIECE_MASK
                    cmp __masker
                    bcs .next       ; pawns only!
                    cmp __masker+1
                    bcc .next
                    tay

                    lda HandlerVectorLO-1,y
                    sta __vector
                    lda HandlerVectorHI-1,y
                    sta __vector+1
                    jmp (__vector)


.exit               lda currentPly ;savedBank
                    sta SET_BANK_RAM



    ; Scan for capture of king

                    lda #0
                    sta flagCheck
                    ldx moveIndex
                    inx
                    stx@RAM moveCounter
                    dex
.nextCheck          dex
                    bmi .end
.scanCheck          lda@PLY MoveCapture,x
                    and #PIECE_MASK
                    cmp #KING
                    bne .nextCheck
                    sta flagCheck

.end                rts


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

                    ldy@RAM moveIndex
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

 
                    lda #RAMBANK_PLY
                    sta currentPly                    
                    sta SET_BANK_RAM                ; switch in movelist
                    
                    jsr selectmove

                    lda bestMove
                    bpl .notComputer

    ; Computer could not find a valid move. It's checkmate or stalemate. Find which...

                    SWAP

                    jsr GenerateAllMoves
                    lda flagCheck
                    beq .gameDrawn

                    PHASE AI_CheckMate
                    rts


.gameDrawn          PHASE AI_Draw
                    rts
                    
.notComputer        PHASE AI_MoveIsSelected
.halted             rts



     ;---------------------------------------------------------------------------------------------------

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.

    ; First, nominate referencing subroutines so that local variables can be adjusted properly

        REFER negamax
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

                    lda #RAMBANK_BOARD
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


                    ;ldy toX12
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

    DEF EnPassantReP_MovePiece
    SUBROUTINE

        REFER SpecialBody
        VEND EnPassantReP_MovePiece

                    jsr DeletePiece                 ; adjust material/position evaluation

                    lda sideToMove
                    and #127
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

                    jsr EnPassantReP_MovePiece

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

        REFER EnPassantReP_MovePiece
        REFER SpecialBody
        VAR __y, 1
        VAR __col, 1
        VEND DeletePiece

                    sty __y

                    lda #RAMBANK_BOARD
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
    include "Handler_KNIGHT.asm"

;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE
    ; =57 including call

    ; add square in y register to movelist as destination (X12 format)
    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece. ENPASSANT flag set if pawn double-moving off opening rank
    ; capture           captured piece

                    lda currentPly                  ; 3
                    sta SET_BANK_RAM                ; 3

                    tya                             ; 2

                    ldy@RAM moveIndex               ; 3
                    iny                             ; 2
                    sty@RAM moveIndex               ; 4

                    sta@PLY MoveTo,y                ; 5
                    tax                             ; 2 new square (for projections)

                    lda currentSquare               ; 3
                    sta@PLY MoveFrom,y              ; 5
                    lda currentPiece                ; 3
                    sta@PLY MovePiece,y             ; 5
                    lda capture                     ; 3
                    sta@PLY MoveCapture,y           ; 5

                    and #PIECE_MASK
                    cmp #KING
                    bne .nKing



.nKing              lda #RAMBANK_BOARD          ; 2 TODO: NOT NEEDED IF FIXED BANK CALLED THIS
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
                    lda #RAMBANK_BOARD
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

    DEF GetValid
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda ValidSquare,y
                    ldy savedBank
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetBoard
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK
                    rts

    DEF GetBoardRAM
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK_RAM
                    rts

;---------------------------------------------------------------------------------------------------

    DEF PutBoard
                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y             ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF IsValidP_MoveFromSquare
    SUBROUTINE

        REFER aiSelectStartSquare
        VEND IsValidP_MoveFromSquare

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
        REFER UNSAFE_showP_MoveCaptures
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
                    lda@PLY moveIndex
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

    DEF SAFE_showP_MoveCaptures
    SUBROUTINE

        VEND SAFE_showP_MoveCaptures

                    JSROM UNSAFE_showP_MoveCaptures
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetP_MoveFrom
                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MoveFrom,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetP_MoveTo
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MoveTo,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetP_MovePiece
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MovePiece,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF MakeMove
    SUBROUTINE

        REFER negamax
        VAR __capture, 1
        VAR __restore, 1
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
                    lda@PLY MoveFrom,x
                    sta fromX12
                    sta originX12
                    lda@PLY MoveTo,x
                    sta toX12
                    lda@PLY MovePiece,x
                    sta fromPiece                   

.move               jsr AdjustMaterialPositionalValue

    ; Modify the board
    
                    ldy #RAMBANK_BOARD
                    sty SET_BANK_RAM
                    ldy originX12
                    lda Board,y
                    sta __restore
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
                    lda __restore
                    sta@RAM restorePiece

    IF CASTLING_ENABLED

        ; If the FROM piece has the castle bit set (i.e., it's a king that's just moved 2 squares)
        ; then we find the appropriate ROOK, set the secondary piece "undo" information, and then
        ; redo the moving code (for the rook, this time).

                    jsr GenCastleMoveForRook
                    bcs .move                       ; move the rook!
    ENDIF


    IF ENPASSANT_ENABLED
    
                    JSROM EnPassantCheck
                    beq .notEnPassant
                    jsr EnPassantReP_MovePiece        ; y = origin X12
.notEnPassant
    ENDIF

    ; Swap over sides

                    NEGEVAL
                    SWAP

                    rts


;---------------------------------------------------------------------------------------------------

    DEF unmake_move
    SUBROUTINE

        REFER negamax
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
                    lda@PLY MoveFrom,x
                    sta fromX12
                    ldy MoveTo,x

                    lda restorePiece
                    pha
                    lda capturedPiece

                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y
                    ldy fromX12
                    pla
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


                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y                     ; put piece back

                    ldy __secondaryBlank
                    lda #0
                    sta@RAM Board,y                     ; blank piece origin

                    lda currentPly
                    sta SET_BANK_RAM


.noSecondary
                    SWAP
                    rts


;---------------------------------------------------------------------------------------------------

;function negamax(node, depth, α, β, color) is
;    if depth = 0 or node is a terminal node then
;        return color × the heuristic value of node

;    childNodes := generateMoves(node)
;    childNodes := orderMoves(childNodes)
;    value := −∞
;    foreach child in childNodes do
;        value := max(value, −negamax(child, depth − 1, −β, −α, −color))
;        α := max(α, value)
;        if α ≥ β then
;            break (* cut-off *)
;    return value
;(* Initial call for Player A's root node *)
;negamax(rootNode, depth, −∞, +∞, 1)


    SUBROUTINE

.terminal

    NEXT_RANDOM
    and #63
                    adc Evaluation
                    sta __negamax
                    lda Evaluation+1
                    adc #0
                    sta __negamax+1
                    rts

.exit               lda@PLY value
                    sta __negamax
                    lda@PLY value+1
                    sta __negamax+1
                    rts


    DEF negamax

    ; pass...
    ; x = depthleft
    ; SET_BANK_RAM      --> current ply
    ; __alpha[2] = param alpha
    ; __beta[2] = param beta


        COMMON_VARS_ALPHABETA
        REFER selectmove
        VEND negamax

                    dex
                    bmi .terminal
                    stx@PLY depthLeft

                    lda __alpha
                    sta@PLY alpha
                    lda __alpha+1
                    sta@PLY alpha+1

                    lda __beta
                    sta@PLY beta
                    lda __beta+1
                    sta@PLY beta+1


                    jsr NewPlyInitialise
                    jsr GenerateAllMoves

                    ;lda flagCheck
                    ;bne .terminate                  ; we can capture the king, so just return for that to be fixed on previous ply

                    jsr Sort


#if 1
                    lda@PLY moveIndex
                    asl
                    asl
                    adc@PLY SavedEvaluation
                    sta@PLY SavedEvaluation
                    lda@PLY SavedEvaluation+1
                    adc #0
                    sta@PLY SavedEvaluation+1                ; + mobility (kind of odd/bad - happens every level)
#endif


                    lda #<-INFINITY
                    sta@PLY value
                    lda #>-INFINITY
                    sta@PLY value+1

                    ldx@PLY moveIndex
                    bmi .exit
                    
.forChild           stx@PLY movePtr

                    jsr MakeMove



    ;        value := max(value, −negamax(child, depth − 1, −β, −α, −color))

    ; PARAMS depth-1, -beta, -alpha
    ; pased through temporary variables (__alpha, __beta) and X reg

                    sec
                    lda #0
                    sbc@PLY beta
                    sta __alpha
                    lda #0
                    sbc@PLY beta+1
                    sta __alpha+1

                    sec
                    lda #0
                    sbc@PLY alpha
                    sta __beta
                    lda #0
                    sbc@PLY alpha+1
                    sta __beta+1

                    ldx@PLY depthLeft

                    inc currentPly
                    lda currentPly
                    sta SET_BANK_RAM                ; self-switch

                    jsr negamax

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    jsr unmake_move

                    sec
                    lda #0
                    sbc __negamax
                    sta __negamax
                    lda #0
                    sbc __negamax+1
                    sta __negamax+1                 ; -negamax(...)


                    sec
                    lda@PLY value
                    sbc __negamax
                    lda@PLY value+1
                    sbc __negamax+1
                    bvc .lab0
                    eor #$80
.lab0               bpl .lt0                        ; branch if value >= negamax

    ; so, negamax > value!

                    lda __negamax
                    sta@PLY value
                    lda __negamax+1
                    sta@PLY value+1                 ; max(value, -negamax)

                    lda@PLY movePtr
                    sta@PLY bestMove
.lt0

;        α := max(α, value)

                    sec
                    lda@PLY value
                    sbc@PLY alpha
                    lda@PLY value+1
                    sbc@PLY alpha+1
                    bvc .lab1
                    eor #$80
.lab1               bmi .lt1                        ; value < alpha

                    lda@PLY value
                    sta@PLY alpha
                    lda@PLY value+1
                    sta@PLY alpha+1                 ; alpha = max(alpha, value)

.lt1

;        if α ≥ β then
;            break (* cut-off *)

                    sec
                    lda@PLY alpha
                    sbc@PLY beta
                    lda@PLY alpha+1
                    sbc@PLY beta+1
                    bvc .lab2
                    eor #$80
.lab2               bpl .retrn                      ; alpha >= beta


                    ldx@PLY movePtr
                    dex
                    bmi .retrn
                    jmp .forChild

.retrn              jmp .exit

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
