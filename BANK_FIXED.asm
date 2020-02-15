; Chess
; Atari 2600 Chess display system
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

                    sei
                    cld
                    ldx #$FF
                    txs


    ; See if we can come up with something 'random' for startup

                    ldy INTIM
                    bne .toR
                    ldy #$9A
.toR                sty rnd

                    ;lda #BANK_TitleScreen
                    ;sta SET_BANK
                    ;jsr TitleScreen


    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                    JSRAM_SAFE SetupBanks

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; rts
                    sta SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE


                    lda currentPly
                    sta SET_BANK_RAM
                    jsr NewPlyInitialise                ; must be called at the start of every new ply

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    jsr InitialisePieceSquares

                    jsr InitialiseChessboard

    ; Now the board is "living" in RAM (along with support code) we can do stuff with it

                    lda #0
                    sta drawPhase

;---------------------------------------------------------------------------------------------------

                    ;RESYNC
.StartFrame


    ; START OF FRAME

                    lda #%1110                       ; VSYNC ON
.loopVSync3         sta WSYNC
                    sta VSYNC
                    lsr
                    bne .loopVSync3                  ; branch until VYSNC has been reset

                    ldy #55 ;VBLANK_TIM_NTSC
                    sty TIM64T

    ; LOTS OF PROCESSING TIME - USE IT

                    ldx #0
                    stx VBLANK


        IF ASSERTS
;                    lda #$C2
;                    sta COLUBK                      ; colour timing band top of screen
        ENDIF

                    lda #STATEMACHINE
                    sta SET_BANK
STATEMAC            jsr AiStateMachine

                    jsr SAFE_PhasedProcessor

        IF ASSERTS
;                    lda #0
;                    sta COLUBK                      ; end of timing band
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

                    lda #%01000010                  ; bit6 is not required
                    sta VBLANK                      ; end of screen - enter blanking

                    lda #0
                    sta PF0
                    sta PF1
                    sta PF2
                    sta GRP0
                    sta GRP1

; END OF VISIBLE SCREEN
; HERE'S SOME TIME TO DO STUFF

                    lda #26
                    sta TIM64T

;
                    JSRAM PositionSprites



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


;---------------------------------------------------------------------------------------------------


    DEF AiStateMachine
    SUBROUTINE

                    lda #STATEMACHINE
                    sta savedBank
                    sta SET_BANK

                    ldx aiPhase
                    lda AiVectorLO,x
                    sta __ptr
                    lda AiVectorHI,x
                    sta __ptr+1
                    jmp (__ptr)


    DEF SAFE_PhasedProcessor

                jsr PhaseJump
                lda savedBank
                sta SET_BANK
                rts

    DEF PhaseJump

                ldx drawPhase
                lda DrawVectorLO,x
                sta __ptr
                lda DrawVectorHI,x
                sta __ptr+1
                lda DrawVectorBANK,x
                sta savedBank
                sta SET_BANK
                jmp (__ptr)

MARCH = 10
STARTMOVE = 4
CSL = 7

DrawVectorLO
    .byte <StartClearBoard
    .byte <ClearEachRow
    .byte <DrawEntireBoard
    .byte <DEB2
    .byte <FlipBuffers
    .byte <FB0
    .byte <FB2
    .byte <FB3
    .byte <EraseStartPiece
    .byte <WriteStartPieceBlank
    .byte <MarchToTargetA
    .byte <MarchB
    .byte <MarchToTargetB
    .byte <MarchB2
    .byte <FinalFlash
    .byte <SpecialMoveFixup

DrawVectorHI
    .byte >StartClearBoard
    .byte >ClearEachRow
    .byte >DrawEntireBoard
    .byte >DEB2
    .byte >FlipBuffers
    .byte >FB0
    .byte >FB2
    .byte >FB3
    .byte >EraseStartPiece
    .byte >WriteStartPieceBlank
    .byte >MarchToTargetA
    .byte >MarchB
    .byte >MarchToTargetB
    .byte >MarchB2
    .byte >FinalFlash
    .byte >SpecialMoveFixup

DrawVectorBANK

    .byte BANK_StartClearBoard
    .byte BANK_ClearEachRow
    .byte BANK_DrawEntireBoard
    .byte BANK_DEB2
    .byte BANK_FlipBuffers
    .byte BANK_FB0
    .byte BANK_FB2
    .byte BANK_FB3
    .byte BANK_EraseStartPiece
    .byte BANK_WriteStartPieceBlank
    .byte BANK_MarchToTargetA
    .byte BANK_MarchB
    .byte BANK_MarchToTargetB
    .byte BANK_MarchB2
    .byte BANK_FinalFlash
    .byte BANK_SpecialMoveFixup



    DEF CallClear

        sty SET_BANK_RAM
        jsr ClearRowBitmap

_rts    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_Get64toX12Board

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldy Base64ToIndex,x
                lda Board,y
                ldy savedBank
                sty SET_BANK
                rts

;---------------------------------------------------------------------------------------------------


    DEF DrawEntireBoard

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                ldx drawPieceNumber
                ldy Base64ToIndex,x
                lda Board,y
                beq isab
                pha
                lda #BLANK
                sta Board+RAM_WRITE,y

                jsr CopySinglePiece

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldx drawPieceNumber
                ldy Base64ToIndex,x
                pla
                sta Board+RAM_WRITE,y


isab            inc drawPhase
.incomplete     rts


;---------------------------------------------------------------------------------------------------


; NOTE: to draw "track" set the blank square tO BLACK


    ; Now we've finished drawing the screen square by square.

;---------------------------------------------------------------------------------------------------

    DEF FlipBuffers

    ; Initialise for a new move

                lda currentPly
                sta SET_BANK_RAM

                jsr NewPlyInitialise                ; zap movelist for this ply

                lda enPassantSquare                 ; potentially set by move in previous ply
                sta enPassantPawn                   ; grab enPassant flag from PLY for later checking

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF FB0

    ; Call move generation for all pieces
    ; Test alpha-beta

                lda currentPly
                sta SET_BANK_RAM
                jsr alphaBeta

                lda currentPly
                sta SET_BANK_RAM
                jsr GenerateMovesForNextPiece

                lda piecelistIndex
                and #15
                cmp #0
                bne .waitgen

                inc drawPhase
.waitgen        rts

;---------------------------------------------------------------------------------------------------

    DEF FB2

    ; Choose one of the moves

                lda currentPly
                sta SET_BANK_RAM                ; switch in movelist

                lda moveIndex
                cmp #-1
                beq .halted                      ; no valid moves


                lda #-1
                sta fromSquare
                sta toSquare

                lda sideToMove
                bpl .notComputer

                jsr MoveViaList

.notComputer
                inc drawPhase
.halted         rts

;---------------------------------------------------------------------------------------------------

    DEF catch
    rts



    DEF MarchToTargetA

    ; Start marching towards destination

                lda drawDelay
                beq .progress
                ;dec drawDelay
                ;rts
.progress


                lda fromSquare
                cmp toSquare
                beq .unmoved

    ; Now we calculate move to new square

                lda fromSquare
                sta lastSquare
                lsr
                lsr
                lsr
                sta __fromRow
                lda toSquare
                lsr
                lsr
                lsr
                cmp __fromRow
                beq rowOK
                bcs .downRow
                lda fromSquare
                sbc #7
                sta fromSquare
                jmp nowcol
.downRow        lda fromSquare
                adc #7
                sta fromSquare
rowOK
nowcol

                lda fromSquare
                and #7
                sta __fromRow
                lda toSquare
                and #7
                cmp __fromRow
                beq colok
                bcc .leftCol
                inc fromSquare
                jmp colok
.leftCol        dec fromSquare
colok

    ; erase object in new sqare --> blank

                ldx fromSquare
                stx drawPieceNumber
                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldy Base64ToIndex,x
                lda Board,y
                beq .skipbl
                jsr CopySinglePiece             ; erase next square along --> blank

.skipbl         lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldx fromSquare
                ldy Base64ToIndex,x

                lda Board,y
                sta lastPiece                   ; what we are overwriting
                lda fromPiece
                and #~CASTLE
                sta Board+RAM_WRITE,y           ; and what's actually moving there
                inc drawPhase

.unmoved        rts

;---------------------------------------------------------------------------------------------------



    DEF MarchToTargetB

                lda drawDelay
                beq .mb
                ;dec drawDelay
                ;rts
.mb


    ; now we want to undraw the piece in the old square

                lda lastSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; erase whatever was on the previous square (completely blank)

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                lda previousPiece

                ldx lastSquare
                ldy Base64ToIndex,x
                sta Board+RAM_WRITE,y

                lda lastPiece
                sta previousPiece

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF MarchB2

                ldx lastSquare
                stx drawPieceNumber

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldy Base64ToIndex,x
                lda Board,y
                beq .skipbl2

                jsr CopySinglePiece             ; draw previous piece back in old position
.skipbl2
                lda fromSquare
                cmp toSquare
                beq xhalt

                lda #0            ; inter-move segment speed (can be 0)
                sta drawDelay

                lda #MARCH
                sta drawPhase
                rts





KSquare         .byte 2,6,58,62
RSquareStart    .byte 22,29,92,99
RSquareEnd      .byte 25,27,95,97
RSquareStart64  .byte 0,7,56,63
RSquareEnd64    .byte 3,5,59,61

xhalt

                jsr FinaliseMove


                lda #4               ; on/off count
                sta drawCount           ; flashing for piece about to move
                lda #0
                sta drawDelay

                inc drawPhase
                rts


;---------------------------------------------------------------------------------------------------

    DEF SpecialMoveFixup

                JSRAM_SAFE CastleFixup

    ; Handle en-passant captures

                lda fromPiece
                and #ENPASSANT
                beq .noEP


    ; TODO - handle the en-passant capture and fixup

.noEP



                lda #STARTMOVE
                sta drawPhase

#if ASSERTS
                JSRAM_SAFE DIAGNOSTIC_checkPieces
#endif

                lda sideToMove
                bmi .skip
                lda #0
                sta aiPhase
.skip



                rts


;---------------------------------------------------------------------------------------------------

    DEF MoveForSinglePiece

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                ldx currentSquare               ; used in move handlers
                lda Board,x
                sta currentPiece

    IF ASSERTS
    eor sideToMove
lock2    bmi lock2
    lda currentPiece
    ENDIF

                and #PIECE_MASK
                tay


    IF ASSERTS
lock    beq lock                    ; catch errors



    ENDIF

                lda HandlerVectorLO-1,y
                sta __vector
                lda HandlerVectorHI-1,y
                sta __vector+1

                jmp (__vector)

MoveReturn      lda currentPly
                sta SET_BANK_RAM

                rts

    OPTIONAL_PAGEBREAK "Vector Tables", 15
    .byte 0     ; dummy to prevent page cross access on index 0

HandlerVectorLO

    .byte <Handle_WHITE_PAWN
    .byte <Handle_BLACK_PAWN
    .byte <Handle_KNIGHT
    .byte <Handle_BISHOP
    .byte <Handle_ROOK
    .byte <Handle_QUEEN
    .byte <Handle_KING

HandlerVectorHI

    .byte >Handle_WHITE_PAWN
    .byte >Handle_BLACK_PAWN
    .byte >Handle_KNIGHT
    .byte >Handle_BISHOP
    .byte >Handle_ROOK
    .byte >Handle_QUEEN
    .byte >Handle_KING

;---------------------------------------------------------------------------------------------------

    include "Handler_PAWN.asm"
    include "Handler_KNIGHT.asm"

;---------------------------------------------------------------------------------------------------

    DEF AddMove

    ; add square in y register to movelist as destination (X12 format)
    ; currentPiece = piece moving
    ; currentSquare = start square (X12)
    ; ??do not modify y

                lda currentPly
                sta SET_BANK_RAM

    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece. ENPASSANT flag set if pawn double-moving off opening rank
    ; do not modify [Y]

    ; add a move to the movelist

                tya

                ldy moveIndex
                iny
                sty moveIndex+RAM_WRITE

                sta MoveTo+RAM_WRITE,y
                tax                             ; new square (for projections)

                lda currentSquare
                sta MoveFrom+RAM_WRITE,y
                lda currentPiece
                sta MovePiece+RAM_WRITE,y

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                rts

;---------------------------------------------------------------------------------------------------


    DEF InitialisePieceSquares

    ; Zap the board with the "blank" ROM copy

                JSRAM_SAFE PutAllPieces

    ; Initialise the piecelists and the board for the two piecelist banks (BLACK/WHITE)

                lda #RAMBANK_PLY
                sta SET_BANK_RAM
                jsr InitPieceLists           ; for white
                lda #RAMBANK_PLY+1
                sta SET_BANK_RAM
                jsr InitPieceLists           ; for black

SetupBoard

    ; Now setup the board/piecelists

                ldx #0
.fillPieceLists

                lda #RAMBANK_PLY
                sta SET_BANK_RAM

                lda InitPieceList,x               ; colour/-1
                beq .finBoardSetup

                asl
                lda #RAMBANK_PLY
                adc #0
                sta SET_BANK_RAM                    ; BLACK/WHITE

                ldy PieceListPtr
                iny

                lda InitPieceList+1,x                 ; square
                sta PieceSquare+RAM_WRITE,y
                tya
                sta SortedPieceList+RAM_WRITE,y

                lda InitPieceList,x               ; piece type
                sta PieceType+RAM_WRITE,y
                pha

                sty PieceListPtr+RAM_WRITE


                ldy InitPieceList+1,x                 ; square

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                pla
                sta Board+RAM_WRITE,y

                inx
                inx
                bpl .fillPieceLists

.finBoardSetup
FinBoard

                rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_GetPieceFromBoard

    ; y = X12 board index

                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    ldx savedBank
                    lda Board,y
                    stx SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF calculateFromSquare
    SUBROUTINE

                    lda highlight_row
                    eor #7
                    asl
                    asl
                    asl
                    ora highlight_col
                    tax

                    stx aiFromSquare
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_IsValidMoveFromSquare

    ; Does the square exist in the movelist?

                    jsr calculateFromSquare

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy Base64ToIndex,x
                    sty aiFromSquareX12

;                    lda Board,y     ; should be the movelist piece
;                    sta aiPiece
                    tya

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListFromSquare

                    lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_IsValidMoveToSquare

    ; Does the square exist in the movelist?

                    lda highlight_row
                    eor #7
                    asl
                    asl
                    asl
                    ora highlight_col
                    tax

                    stx aiToSquare

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Base64ToIndex,x
                    sta aiToSquareX12

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListToSquare

.found              lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_PutPieceToBoard

    ; y = board index
    ; a = piece

                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    sta Board+RAM_WRITE,y
                    ldx savedBank
                    stx SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_CopyShadowROMtoRAM
                jsr CopyShadowROMtoRAM
                lda savedBank
                sta SET_BANK
                rts

    DEF CopyShadowROMtoRAM
    ; pass x = source bank
    ; pass y = destination bank (preserved)

                stx __sourceBank

                ldx #0
.copyPage       lda __sourceBank
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
                rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_CopySinglePiece

                jsr CopySinglePiece
                lda savedBank
                sta SET_BANK
                rts


    DEF CopySinglePiece


                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                jsr CopySetup

    DEF InterceptMarkerCopy

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
.copyP          lda (__ptr),y
                sta __pieceShapeBuffer,y
                dey
                bpl .copyP


                lda drawPieceNumber
                lsr
                lsr
                lsr
                eor #7
                tax

                lda drawPieceNumber
                and #4
                cmp #4                      ; cc = left side, cs = right side

                stx SET_BANK_RAM
                jmp CopyPieceToRowBitmap

;---------------------------------------------------------------------------------------------------

    DEF MoveViaList

                lda currentPly
                sta SET_BANK_RAM                ; switch in movelist

                jsr MoveViaListAtPly
                rts

;---------------------------------------------------------------------------------------------------

    DEF FinaliseMove

    ; Now the visible movement on the board has happened, fix up the pointers to the pieces
    ; for both sides.


                lda sideToMove
                asl
                lda #RAMBANK_PLY
                adc #0
                sta SET_BANK_RAM

                jsr FixPieceList

                lda toX12
                sta fromX12                 ; there MAY be no other-side piece at this square - that is OK!
                lda #0
                sta toX12                   ; --> deleted (square=0)

                lda lastPiece
                beq .notake

                lda sideToMove
                eor #128
                asl
                lda #RAMBANK_PLY
                adc #0
                sta SET_BANK_RAM

                jsr FixPieceList            ; REMOVE any captured object

    ; And swap sides to move...

.notake         lda sideToMove
                eor #128
                sta sideToMove

                rts

;---------------------------------------------------------------------------------------------------


    DEF InitialiseChessboard

                lda #WHITE
                sta sideToMove
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

    DEF SAFE_showMoveOptions
    SUBROUTINE

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next           ldx aiMoveIndex
                bmi .skip

                lda INTIM
                cmp #SAFETIME
                bcc .skip

                lda #RAMBANK_PLY            ; white
                sta SET_BANK_RAM

                dec aiMoveIndex

                lda MoveFrom,x
                cmp aiFromSquareX12
                bne .next

                ldy MoveTo,x

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                lda Board,y
                bne .next

                lda drawPieceNumber
                pha

                lda X12toBase64,y
                sta drawPieceNumber

                jsr CopySetupForMarker
                jsr InterceptMarkerCopy

                pla
                sta drawPieceNumber

.dontDrawCaptures
.skip           lda savedBank
                sta SET_BANK
                rts


SAFETIME = 40           ; time required to be able to safely do a piece draw TODO: optimise

    DEF SAFE_showMoveCaptures
    SUBROUTINE

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next           ldx aiMoveIndex
                bmi .skip

                lda INTIM
                cmp #24 ;SAFETIME
                bcc .skip

                lda #RAMBANK_PLY            ; white
                sta SET_BANK_RAM
                dec aiMoveIndex

                lda MoveFrom,x
                cmp aiFromSquareX12
                bne .next

                ldy MoveTo,x

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                lda Board,y
                beq .next

                lda drawPieceNumber
                pha

                lda X12toBase64,y
                sta drawPieceNumber

                jsr CopySinglePiece

                pla
                sta drawPieceNumber

.dontDrawBlanks
.skip           lda savedBank
                sta SET_BANK
                rts


    OPTIONAL_PAGEBREAK "X12toBase64", 100

X12toBase64

    ; Use this table to
    ;   a) Determine if a square is valid (-1 = NO)
    ;   b) Move pieces without addition.  e.g., "lda ValidSquareTable+10,x" will let you know
    ;      if a white pawn on square "x" can move "up" the board.

    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    .byte -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    .byte -1, -1,  0,  1,  2,  3,  4,  5,  6,  7
    .byte -1, -1,  8,  9, 10, 11, 12, 13, 14, 15
    .byte -1, -1, 16, 17, 18, 19, 20, 21, 22, 23
    .byte -1, -1, 24, 25, 26, 27, 28, 29, 30, 31
    .byte -1, -1, 32, 33, 34, 35, 36, 37, 38, 39
    .byte -1, -1, 40, 41, 42, 43, 44, 45, 46, 47
    .byte -1, -1, 48, 49, 50, 51, 52, 53, 54, 55
    .byte -1, -1, 56, 57, 58, 59, 60, 61, 62, 63


    ECHO "FREE BYTES IN FIXED BANK = ", $FFFC - *

;---------------------------------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the fixed bank (last 2K of any ROM image in TigerVision)

    SEG InterruptVectors
    ORG FIXED_BANK + $7FC
    RORG $7ffC

;               .word Reset           ; NMI        (not used)
                .word Reset           ; RESET
                .word Reset           ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
; EOF
