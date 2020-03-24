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

                    sei
                    cld
                    ldx #$FF
                    txs


    ; See if we can come up with something 'random' for startup

                    ldy INTIM
                    bne .toR
                    ldy #$9A
.toR                sty rnd

                    ;JSROM TitleScreen

                    JSROM ShutYourMouth

    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                    JSROM_SAFE SetupBanks

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE


                    lda currentPly
                    sta SET_BANK_RAM
                    jsr NewPlyInitialise            ; must be called at the start of every new ply

                    JSROM InitialisePieceSquares

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


        IF ASSERTS
;                    lda #$C2
;                    sta COLUBK                     ; colour timing band top of screen
        ENDIF

                    jsr AiStateMachine

                    ;jsr SAFE_PhasedProcessor

        IF ASSERTS
;                    lda #0
;                    sta COLUBK                     ; end of timing band
        ENDIF

#if ASSERTS
; Catch timer expired already
                    bit TIMINT
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

                    JSROM AiSetupVectors
                    ;bcs .exit                   ; not enough time
                    sta SET_BANK
                    jmp (__ptr)                 ; TODO: OR branch back to squeeze cycles

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF CallClear
    SUBROUTINE

                    sty SET_BANK_RAM
                    jsr ClearRowBitmap
                    rts

;---------------------------------------------------------------------------------------------------


    DEF aiDrawEntireBoard
    SUBROUTINE


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
                    sta Board+RAM_WRITE,y

                    jsr CopySinglePiece

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    ldy squareToDraw
                    pla
                    sta Board+RAM_WRITE,y

.isablank           PHASE AI_DrawPart2
                    rts

.isablank2          PHASE AI_DrawPart3
.exit               rts

;---------------------------------------------------------------------------------------------------

    DEF aiFlipBuffers
    SUBROUTINE

    ; Initialise for a new move

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise            ; zap movelist for this ply

                    PHASE AI_GenerateMoves
                    rts


;---------------------------------------------------------------------------------------------------

    DEF InitialiseMoveGeneration
    SUBROUTINE

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GenerateOneMove
    SUBROUTINE

                    lda currentPly
                    sta SET_BANK_RAM
                    jsr GenerateMovesForNextPiece

                    lda savedBank
                    sta SET_BANK
                    rts


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

    ; Choose one of the moves

                    lda currentPly
                    sta SET_BANK_RAM                ; switch in movelist

                    lda #-1
                    cmp moveIndex
                    beq .halted                     ; no valid moves

                    ;sta fromX12
                    sta originX12
                    sta toX12

                    lda sideToMove
                    bpl .notComputer

                    jsr MoveViaListAtPly

.notComputer        PHASE AI_MoveIsSelected
.halted             rts


;---------------------------------------------------------------------------------------------------

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.
    
        VAR __pval, 2
        VAR __originalPiece, 1
        VAR __capturedPiece, 1

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

    DEF SpecialBody
    SUBROUTINE



    ; Handle en-passant captures
    ; The (dual-use) FLAG_ENPASSANT will have been cleared if it was set for a home-rank move
    ; but if we're here and the flag is still set, then it's an actual en-passant CAPTURE and we
    ; need to do the appropriate things...


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


    ; {
    ; Check to see if we are doing an actual en-passant capture...

    ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
    ;  as the en-passant will fail if the taking piece does not have this flag set correctly

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece

    ; Here we are the aggressor and we need to take the pawn 'en passant' fashion
    ; y = the square containing the pawn to capture (i.e., previous value of 'enPassantPawn')

    ; Remove the pawn from the board and piecelist, and undraw

                    sty originX12                   ; rqd for FixPieceList
                    sty squareToDraw

                    jsr CopySinglePiece             ; undraw captured pawn

                    ldy originX12                   ; taken pawn's square
                    jsr DeletePiece                 ; adjust material/position evaluation

                    lda sideToMove
                    eor #128
                    asl                             ; --> C
                    lda #0
                    adc #RAMBANK_PLY                ; <-- C
                    sta SET_BANK_RAM

                    jsr FixPieceList                ; from the piecelist

.notEnPassant

    ; }

                    JSROM CastleFixup

    ; Mark the piece as MOVED

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy fromX12                     ; final square
                    lda Board,y
                    and #~FLAG_ENPASSANT            ; probably superflous
                    ora #FLAG_MOVED
                    sta Board+RAM_WRITE,y


                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
                    bcs .cont
                    rts

.cont
                    PHASE AI_FlipBuffers


                    jsr SpecialBody



#if ASSERTS
;                    JSROM_SAFE DIAGNOSTIC_checkPieces
#endif

                   rts


;---------------------------------------------------------------------------------------------------

    DEF HeadlessMove
    SUBROUTINE

    ; Do a move without any GUI stuff

    ; fromPiece     piece doing the move
    ; fromSquare    starting square BASE64
    ; toSquare      ending square BASE64
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12


                    jsr AdjustMaterialPositionalValue
                    jsr SpecialBody                     ;TODO: stop draw of enpassant delete

                    rts


;---------------------------------------------------------------------------------------------------

    DEF DeletePiece
    SUBROUTINE

    ; Based on piece square, adjust material and position value with piece deleted
    ; y = piece square

        VAR __y, 1
        VAR __col, 1

                    sty __y

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y                     ; piece type

                    sta __col
                    and #PIECE_MASK
                    tay

                   ; NEGEVAL

                    lda #BANK_AddPieceMaterialValue
                    sta SET_BANK
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; adding for opponent = taking

                   ; NEGEVAL

                    rts


;---------------------------------------------------------------------------------------------------

    DEF MoveForSinglePiece
    SUBROUTINE


                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    ldx currentSquare               ; used in move handlers
                    lda Board,x
                    sta currentPiece

    IF ASSERTS
    SUBROUTINE
    ; DEBUG: Make sure we're looking at correct colour
                    eor sideToMove
.lock               bmi .lock
                    lda currentPiece
    ENDIF

                    and #PIECE_MASK
                    tay

    IF ASSERTS
    ; DEBUG: Make sure we have an actual piece, not an empty square
    SUBROUTINE
.lock               beq .lock                       ; catch errors
    ENDIF

        VAR __vector, 2

                    lda HandlerVectorLO-1,y
                    sta __vector
                    lda HandlerVectorHI-1,y
                    sta __vector+1
                    jmp (__vector)

MoveReturn          lda currentPly
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

    include "Handler_PAWN.asm"

;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE
    ; =57 including call

    ; add square in y register to movelist as destination (X12 format)
    ; currentPiece = piece moving
    ; currentSquare = start square (X12)

                    lda currentPly              ; 3
                    sta SET_BANK_RAM            ; 3

    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece. ENPASSANT flag set if pawn double-moving off opening rank

                    tya                         ; 2

                    ldy moveIndex               ; 3
                    iny                         ; 2
                    sty moveIndex+RAM_WRITE     ; 4

                    sta MoveTo+RAM_WRITE,y      ; 5
                    tax                         ; 2 new square (for projections)

                    lda currentSquare           ; 3
                    sta MoveFrom+RAM_WRITE,y    ; 5
                    lda currentPiece            ; 3
                    sta MovePiece+RAM_WRITE,y   ; 5

                    lda #RAMBANK_MOVES_RAM      ; 2 TODO: NOT NEEDED IF FIXED BANK CALLED THIS
                    sta SET_BANK_RAM            ; 3
                    rts                         ; 6


;---------------------------------------------------------------------------------------------------

    DEF InitialisePieceSquares
    SUBROUTINE

    ; Initialise the piecelists and the board for the two piecelist banks (BLACK/WHITE)

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    jsr InitPieceLists              ; for white
                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    jsr InitPieceLists              ; for black



                    ldx #0
                    stx enPassantPawn               ; no en-passant


    ; We init evaluation as "white"

    ; Now setup the board/piecelists

.fillPieceLists     lda #RAMBANK_PLY
                    sta SET_BANK_RAM

                    lda InitPieceList,x             ; colour/-1
                    bne .go
                    jmp .exit
.go                 sta __originalPiece             ; type

                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM                ; BLACK/WHITE

                    ldy PieceListPtr                ; init'd in InitPieceLists
                    iny

                    lda InitPieceList+1,x           ; square
                    sta PieceSquare+RAM_WRITE,y
                    tya
                    sta SortedPieceList+RAM_WRITE,y

                    lda __originalPiece             ; piece type
                    sta PieceType+RAM_WRITE,y
                    pha

                    sty PieceListPtr+RAM_WRITE


                    ldy InitPieceList+1,x           ; square

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    pla
                    sta Board+RAM_WRITE,y


    ; TODO: if black, toggle eval

                    lda __originalPiece             ; type/colour
                    bpl .white
                    NEGEVAL
.white

    ; Add the material value of the piece to the evaluation

                    lda __originalPiece
                    and #PIECE_MASK
                    tay

                    JSROM AddPieceMaterialValue

                    txa
                    pha

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM

    ; add the positional value of the piece to the evaluation 

                    ldy InitPieceList+1,x           ; square
                    lda __originalPiece             ; type

                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK
                    jsr AddPiecePositionValue


                    pla
                    tax

                    lda __originalPiece             ; type/colour
                    bpl .white2
                    NEGEVAL
.white2

    ; Store the piece's value with the piece itself, so it doesn't have to 
    ; be looked-up everytime it's added/removed
    ; this may be overkill and more effort than it's worth...

                    lda #BANK_PieceValueLO
                    sta SET_BANK

                    lda PieceValueHI,y
                    pha
                    lda PieceValueLO,y
                    pha

                    lda __originalPiece             ; colour/-1
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM                ; BLACK/WHITE

                    ldy PieceListPtr
                    iny


                    pla
                    sta PieceMaterialValueLO+RAM_WRITE,y
                    pla
                    sta PieceMaterialValueHI+RAM_WRITE,y

                    inx
                    inx
                    bmi .exit
                    jmp .fillPieceLists

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_GetKingSquare
    SUBROUTINE

    ; Pass:         A = correct bank for current side (RAMBANK_PLY/+1)
    ; Return:       A = square king is on (or -1)

                    sta SET_BANK_RAM
                    jsr GetKingSquare
                    ldy savedBank
                    sty SET_BANK
                    rts


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


;---------------------------------------------------------------------------------------------------

    DEF PutBoard
                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    sta Board+RAM_WRITE,y           ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF IsValidMoveFromSquare
    SUBROUTINE

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

        VAR __destinationBank, 1
        VAR __sourceBank, 1


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

                    sta $F300+RAM_WRITE,x
                    pla
                    sta $F200+RAM_WRITE,x
                    pla
                    sta $F100+RAM_WRITE,x
                    pla
                    sta $F000+RAM_WRITE,x

                    dex
                    bne .copyPage

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE
    TIMING COPYSINGLEPIECE, (2600)

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

    DEF GoFixPieceList

                    sta SET_BANK_RAM
                    jsr FixPieceList
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF markerDraw

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF Go_IsSquareUnderAttack

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


;---------------------------------------------------------------------------------------------------

    DEF SAFE_showMoveCaptures
    SUBROUTINE

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

                    ldx movePtr

                    lda MoveFrom,x
                    sta fromX12
                    sta originX12
                    lda MoveTo,x
                    sta toX12
                    lda MovePiece,x
                    sta fromPiece

                    rts


;---------------------------------------------------------------------------------------------------


    DEF unmake_move
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

        VAR __return, 2
        VAR __bestValue, 2

    ; we have already done the Evaluation (incrementally)



;    if( stand_pat >= beta ):
;        return beta

                    sec
                    lda Evaluation
                    sbc beta
                    lda Evaluation+1
                    sbc beta+1
                    bcc .endif0

                    lda beta+1
                    sta __return+1
                    lda beta
                    sta __return
                    rts
.endif0

;    if( alpha < stand_pat ):
;        alpha = stand_pat

                    clc             ;!!
                    lda alpha
                    sbc Evaluation
                    lda alpha+1
                    sbc Evaluation+1
                    bcs .endif1

                    lda Evaluation
                    sta alpha  [+RAM_WRITE]
                    lda Evaluation+1
                    sta alpha+1  [+RAM_WRITE]

.endif1


;   generate all moves

                    jsr GenerateAllMoves

                    lda moveIndex
                    sta movePtr  [+RAM_WRITE]

;    for move in board.legal_moves:
;    {

.loopMoves          ldy movePtr
                    bpl .cont

;    return alpha
                    lda alpha
                    sta __return
                    lda alpha+1
                    sta __return+1
                    rts

.cont

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    ldx currentPly
                    stx SET_BANK_RAM
                    and #PIECE_MASK
                    beq .nextMove                   ; only process capture moves


                    jsr MakeMove

;        if board.is_capture(move):
;            make_move(move)

;            score = -quiesce( -beta, -alpha )

                    sec
                    lda #0
                    sbc beta
                    pha
                    lda #0
                    sbc beta+1
                    pha

                    sec
                    lda #0
                    sbc alpha
                    pha
                    lda #0
                    sbc alpha+1
                    pha

                    inc currentPly
                    lda currentPly
                    sta SET_BANK_RAM
                    jsr NewPlyInitialise

                    pla
                    sta beta+1  [+RAM_WRITE]
                    pla
                    sta beta  [+RAM_WRITE]                        ; -alpha

                    pla
                    sta alpha+1  [+RAM_WRITE]
                    pla
                    sta alpha  [+RAM_WRITE]                       ; -beta

                    jsr quiesce

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    sec
                    lda #0
                    sbc __return
                    sta __return
                    lda #0
                    sbc __return+1
                    sta __return+1                     ; score = -quiesce( -beta, -alpha)


; TODO:
;            unmake_move()


;            if( score >= beta ):
;                return beta

                    sec
                    lda __return
                    sbc beta
                    lda __return+1
                    sbc beta+1
                    bcc .endif2

                    lda beta
                    sta __return
                    lda beta+1
                    sta __return+1
                    rts

.endif2

;            if( score > alpha ):
;                alpha = score

                    clc                 ; !!
                    lda alpha
                    sbc __return
                    lda alpha+1
                    sbc __return+1
                    bcs .endif3

                    lda __return
                    sta alpha  [+RAM_WRITE]
                    lda __return+1
                    sta alpha+1  [+RAM_WRITE]
.endif3


    ; end of move iteration/loop

.nextMove           sec
                    lda movePtr
                    sbc #1
                    sta movePtr+RAM_WRITE
                    jmp .loopMoves






;---------------------------------------------------------------------------------------------------

    DEF selectmove
    SUBROUTINE
    
    ; x = depth to go to

;        bestMove = chess.Move.null()
;        bestValue = -99999
;        alpha = -100000
;        beta = 100000

        VAR __return, 2
        VAR __boardValue, 2

                    lda currentPly
                    sta SET_BANK_RAM

                    stx depth [+RAM_WRITE]

                    lda #-1
                    sta bestMove  [+RAM_WRITE]

                    lda #<(-INFINITY)
                    sta alpha  [+RAM_WRITE]
                    lda #>(-INFINITY)
                    sta alpha+1  [+RAM_WRITE]

                    lda #<INFINITY
                    sta beta  [+RAM_WRITE]
                    lda #>INFINITY
                    sta beta+1  [+RAM_WRITE]

                    lda #<(-(INFINITY-1))
                    sta bestValue  [+RAM_WRITE]
                    lda #<(-(INFINITY-1))
                    sta bestValue+1  [+RAM_WRITE]

;        for move in board.legal_moves:
; TODO: we should have generated moves at this point!

                    jsr GenerateAllMoves


                    lda moveIndex
                    sta movePtr [+RAM_WRITE]

.loopMoves          ldx movePtr
                    bpl .validMove
                    
;        movehistory.append(bestMove)
;        return bestMove

                    lda bestMove
                    sta __return
                    rts

.validMove

;            make_move(move)

                    jsr MakeMove

                    sec
                    lda #0
                    sbc alpha
                    pha
                    lda #0
                    sbc alpha+1
                    pha                             ; -alpha

                    sec
                    lda #0
                    sbc beta
                    pha
                    lda #0
                    sbc beta+1
                    pha                             ; -beta

                    ldx depth

                    inc currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    dex
                    stx depth [+RAM_WRITE]

                    pla
                    sta alpha+1  [+RAM_WRITE]
                    pla
                    sta alpha  [+RAM_WRITE]         ; alpha = -beta

                    pla
                    sta beta+1  [+RAM_WRITE]
                    pla
                    sta beta  [+RAM_WRITE]          ; beta  = -alpha

                    ;tmp jsr alphaBeta

;            boardValue = -alphabeta(-beta, -alpha, depth-1)

                    sec
                    lda #0
                    sbc __return
                    sta __boardValue
                    lda #0
                    sbc __return+1
                    sta __boardValue+1

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM


;            if boardValue > bestValue:
;                bestValue = boardValue;

                    clc                         ; !!
                    lda bestValue
                    sbc __boardValue
                    lda bestValue+1
                    sbc __boardValue+1
                    bcs .endif20

                    lda __boardValue
                    sta bestValue
                    lda __boardValue+1
                    sta bestValue+1

;                bestMove = move

                    lda movePtr
                    sta bestMove

.endif20
;            if( boardValue > alpha ):
;                alpha = boardValue

                    clc                     ; !!
                    lda __boardValue
                    sbc alpha
                    lda __boardValue+1
                    sbc alpha+1
                    bcc .endif23

                    lda __boardValue
                    sta alpha
                    lda __boardValue+1
                    sta alpha+1
.endif23

;            unmake_move()
                    jsr unmake_move

                    sec
                    lda movePtr
                    sbc #1
                    sta movePtr  [+RAM_WRITE]
                    sta movePtr

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
