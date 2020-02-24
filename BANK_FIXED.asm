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

                    ;lda #BANK_TitleScreen
                    ;sta SET_BANK
                    ;jsr TitleScreen


    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                    JSRAM_SAFE SetupBanks

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE


                    lda currentPly
                    sta SET_BANK_RAM
                    jsr NewPlyInitialise            ; must be called at the start of every new ply

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
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

                    ;jsr AiStateMachine

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


_rts                rts


;---------------------------------------------------------------------------------------------------

    DEF AiStateMachine
    SUBROUTINE

                    lda #BANK_AiVectorLO
                    sta SET_BANK                ; to access vectors
                    jsr AiSetupVectors
                    bcs .exit
                    sta SET_BANK

                    jsr .ind
                    rts ;tmp jmp AiStateMachine


.exit               rts
.ind                jmp (__ptr)


;---------------------------------------------------------------------------------------------------

;    DEF SAFE_PhasedProcessor
;    SUBROUTINE

;                    jsr PhaseJump
;                    lda savedBank
;                    sta SET_BANK
;                    rts

;---------------------------------------------------------------------------------------------------

    DEF CallClear
    SUBROUTINE

                    sty SET_BANK_RAM
                    jsr ClearRowBitmap
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_Get64toX12Board
    SUBROUTINE

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy Base64ToIndex,x
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiDrawEntireBoard
    SUBROUTINE

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    ldx drawPieceNumber
                    ldy Base64ToIndex,x
                    lda Board,y
                    beq .isablank
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

.isablank           PHASE AI_DEB2
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiFlipBuffers
    SUBROUTINE

    ; Initialise for a new move

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise            ; zap movelist for this ply

                    ;lda enPassantSquare             ; potentially set by move in previous ply
                    ;sta enPassantPawn               ; grab enPassant flag from PLY for later checking

                    PHASE AI_FB0
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_InitialiseMoveGeneration
    SUBROUTINE

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr NewPlyInitialise

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    ;TODO...
    DEF SAFE_GenerateOneMove
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

;lab dc "aiFB0"
;mymac eqm aiFB0 + ..
;mylist dv mymac, 1, 2, 3


    DEF aiFB0
    SUBROUTINE

    ; Call move generation for all pieces
    ; Test alpha-beta

                    ;lda currentPly
                    ;sta SET_BANK_RAM
                    ;jsr alphaBeta

                    lda currentPly
                    sta SET_BANK_RAM
                    jsr GenerateMovesForNextPiece

                    lda piecelistIndex
                    and #15
                    cmp #0
                    beq .stop

                    lda INTIM
                    cmp #15
                    bcs aiFB0
                    rts


.stop               ldx sideToMove
                    bpl .player

                    PHASE AI_FB2                ; computer select move
                    rts


.player             PHASE AI_StartMoveGen
.wait               rts


;---------------------------------------------------------------------------------------------------

    DEF aiFB2
    SUBROUTINE

    ; Choose one of the moves

                    lda currentPly
                    sta SET_BANK_RAM                ; switch in movelist

                    lda moveIndex
                    cmp #-1
                    beq .halted                     ; no valid moves


                    lda #-1
                    sta fromSquare
                    sta toSquare

                    lda sideToMove
                    bpl .notComputer

                    jsr MoveViaList

.notComputer        PHASE AI_FB3
.halted             rts


;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE

    ; Use this to trap breakpoints in "unknown" banks. Just "jsr catch" from wherever you want
    ; to catch the code, and put a breakpoint here instead. Then step, and you're at the place
    ; you wanted to see, without knowing the bank.

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetA
    SUBROUTINE

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
.downRow            lda fromSquare
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
.leftCol            dec fromSquare
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

.skipbl             lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldx fromSquare
                    ldy Base64ToIndex,x

                    lda Board,y
                    sta lastPiece                   ; what we are overwriting
                    lda fromPiece
                    ora #FLAG_MOVED                 ; prevents usage in castling for K/R
                    sta Board+RAM_WRITE,y           ; and what's actually moving there

                    PHASE AI_MarchB

.unmoved            rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchToTargetB
    SUBROUTINE

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

                    PHASE AI_MarchB2

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMarchB2
    SUBROUTINE

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

                    lda #0                          ; inter-move segment speed (can be 0)
                    sta drawDelay
                    PHASE AI_MarchToTargetA

                    rts

xhalt

                    jsr FinaliseMove


                    lda #4                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    PHASE AI_FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

                    PHASE AI_FlipBuffers

                    JSRAM_SAFE CastleFixup


    ; Handle en-passant captures

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    beq .noEP


IsEnpassant

                    ldy enPassantPawn
                    sty fromX12
                    lda X12toBase64,y
                    sta drawPieceNumber

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    jsr CopySinglePiece             ; ERASE pawn


                    lda sideToMove
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM

                    jsr FixPieceList                ; REMOVE any captured object

.noEP



#if ASSERTS
                    JSRAM_SAFE DIAGNOSTIC_checkPieces
#endif

                    rts


;---------------------------------------------------------------------------------------------------

    DEF MoveForSinglePiece
    SUBROUTINE

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    ldx currentSquare               ; used in move handlers
                    lda Board,x
                    sta currentPiece

    ;***********************************************************************************************
    IF ASSERTS
    SUBROUTINE
    ; DEBUG: Make sure we're looking at correct colour
                    eor sideToMove
.lock               bmi .lock
                    lda currentPiece
    ENDIF
    ;***********************************************************************************************

                    and #PIECE_MASK
                    tay

    ;***********************************************************************************************
    IF ASSERTS
    ; DEBUG: Make sure we have an actual piece, not an empty square
    SUBROUTINE
.lock               beq .lock                       ; catch errors
    ENDIF
    ;***********************************************************************************************

                    lda HandlerVectorLO-1,y
                    sta __vector
                    lda HandlerVectorHI-1,y
                    sta __vector+1
                    jmp (__vector)

MoveReturn          lda currentPly
                    sta SET_BANK_RAM

                    rts

    OPTIONAL_PAGEBREAK "Vector Tables", 15

                    .byte 0     ; dummy to prevent page cross access on index 0

HandlerVectorLO
                    .byte <Handle_WHITE_PAWN        ; 1
                    .byte <Handle_BLACK_PAWN        ; 2
                    .byte <Handle_KNIGHT            ; 3
                    .byte <Handle_BISHOP            ; 4
                    .byte <Handle_ROOK              ; 5
                    .byte <Handle_QUEEN             ; 6
                    .byte <Handle_KING              ; 7

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
    SUBROUTINE
    ; =57 including call

    ; add square in y register to movelist as destination (X12 format)
    ; currentPiece = piece moving
    ; currentSquare = start square (X12)
    ; ??do not modify y

                    lda currentPly              ; 3
                    sta SET_BANK_RAM            ; 3

    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece. ENPASSANT flag set if pawn double-moving off opening rank
    ; do not modify [Y]

    ; add a move to the movelist

                    tya                         ; 2

                    ldy moveIndex               ; 3
                    iny                         ; 2
                    sty moveIndex+RAM_WRITE     ; 4

                    sta MoveTo+RAM_WRITE,y      ; 5
                    tax                         ; 2   new square (for projections)

                    lda currentSquare           ; 3
                    sta MoveFrom+RAM_WRITE,y    ; 5
                    lda currentPiece            ; 3
                    sta MovePiece+RAM_WRITE,y   ; 5

                    lda #RAMBANK_MOVES_RAM      ; 2
                    sta SET_BANK_RAM            ; 3
                    rts                         ; 6


;---------------------------------------------------------------------------------------------------

    DEF InitialisePieceSquares
    SUBROUTINE

    ; Zap the board with the "blank" ROM copy

                    JSRAM_SAFE PutAllPieces

    ; Initialise the piecelists and the board for the two piecelist banks (BLACK/WHITE)

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    jsr InitPieceLists              ; for white
                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    jsr InitPieceLists              ; for black


    ; Now setup the board/piecelists

                    ldx #0
.fillPieceLists

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM

                    lda InitPieceList,x             ; colour/-1
                    beq .finish

                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM                ; BLACK/WHITE

                    ldy PieceListPtr
                    iny

                    lda InitPieceList+1,x           ; square
                    sta PieceSquare+RAM_WRITE,y
                    tya
                    sta SortedPieceList+RAM_WRITE,y

                    lda InitPieceList,x             ; piece type
                    sta PieceType+RAM_WRITE,y
                    pha

                    sty PieceListPtr+RAM_WRITE


                    ldy InitPieceList+1,x           ; square

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    pla
                    sta Board+RAM_WRITE,y

                    inx
                    inx
                    bpl .fillPieceLists

.finish             rts


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

    DEF SAFE_GetPieceFromBoard
    SUBROUTINE

    ; y = X12 board index

                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    ldx savedBank
                    lda Board,y
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF calculateBase64Square
    SUBROUTINE

    ; Convert row/column into Base64 index

                    lda highlight_row
                    eor #7
                    asl
                    asl
                    asl
                    ora highlight_col
                    tax
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_IsValidMoveFromSquare
    SUBROUTINE

    ; Does the square exist in the movelist?

                    jsr calculateBase64Square
                    stx aiFromSquare

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy Base64ToIndex,x
                    sty aiFromSquareX12

                    tya

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListFromSquare

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_GetPiece
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

    DEF SAFE_IsValidMoveToSquare
    SUBROUTINE

    ; Does the square exist in the movelist?

                    jsr calculateBase64Square
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
    SUBROUTINE

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
    SUBROUTINE

                    jsr CopyShadowROMtoRAM
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopyShadowROMtoRAM
    SUBROUTINE

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
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_CopySinglePiece
    SUBROUTINE

                    jsr CopySinglePiece
                    lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE
    ; @2150 max
    ; = 33 TIM64T


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

;    DEF BockCopyToRamBuffer

                    ldy #PIECE_SHAPE_SIZE-1
.copy               lda (__ptr),y
                    sta __pieceShapeBuffer,y
                    dey
                    bpl .copy


                    lda drawPieceNumber
                    lsr
                    lsr
                    lsr
                    eor #7
                    tax                             ; ROW

                    lda drawPieceNumber
                    and #4
                    cmp #4                          ; cc = left side, cs = right side

                    stx SET_BANK_RAM
                    jmp CopyPieceToRowBitmap

;---------------------------------------------------------------------------------------------------

    DEF MoveViaList
    SUBROUTINE

    ; Given an existing movelist, pick one of the moves and make it
    ; Used for random computer moves

                    lda currentPly
                    sta SET_BANK_RAM                ; switch in movelist

                    jsr MoveViaListAtPly
                    rts


;---------------------------------------------------------------------------------------------------

    DEF FinaliseMove
    SUBROUTINE

    ; Now the visible movement on the board has happened, fix up the pointers to the pieces
    ; for both sides.


                    lda sideToMove
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM

                    jsr FixPieceList

                    lda toX12
                    sta fromX12                     ; there MAY be no other-side piece at this square - that is OK!
                    lda #0
                    sta toX12                       ; --> deleted (square=0)



                    lda lastPiece
                    beq .notake

                    lda sideToMove
                    eor #128
                    asl
                    lda #RAMBANK_PLY
                    adc #0
                    sta SET_BANK_RAM

                    jsr FixPieceList                ; REMOVE any captured object

.notake             rts


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

;SAFETIME = 40           ; time required to be able to safely do a piece draw TODO: optimise


    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next               ldx aiMoveIndex
                    bmi .skip

                    ;lda INTIM
                    ;cmp #SAFETIME
                    ;bcc .skip

                    lda #RAMBANK_PLY                ; white
                    sta SET_BANK_RAM

                    dec aiMoveIndex

                    lda MoveFrom,x
                    cmp aiFromSquareX12
                    bne .next

                    ldy MoveTo,x

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    lda Board,y
                    bne .next                       ; don't draw dots on captures - they are flashed later

                    lda drawPieceNumber
                    pha

                    lda X12toBase64,y
                    sta drawPieceNumber

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    jsr CopySetupForMarker
                    jsr InterceptMarkerCopy

                    pla
                    sta drawPieceNumber

.skip               lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_showPromoteOptions
    SUBROUTINE

    ; Pass          X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    lda X12toBase64,y
                    sta drawPieceNumber

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    jsr CopySetupForMarker
                    jsr InterceptMarkerCopy

                    lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_IsSquareUnderAttack

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

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next               ldx aiMoveIndex
                    bmi .skip                       ; no moves in list

                    lda #RAMBANK_PLY                ; white
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

.skip               lda savedBank
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

                    .word Reset                     ; RESET
                    .word Reset                     ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
; EOF
