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

                    ;jsr AiStateMachine

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
                    bcs .exit
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


                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy drawPieceNumberX12
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

                    ldy drawPieceNumberX12
                    pla
                    sta Board+RAM_WRITE,y

.isablank           PHASE AI_DrawPart2
                    rts

.isablank2          PHASE AI_DrawPart3
                    rts

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

                    sta fromX12
                    sta originX12
                    sta toX12

                    lda sideToMove
                    bpl .notComputer

                    jsr MoveViaListAtPly

.notComputer        PHASE AI_PrepForPhysicalMove
.halted             rts


;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE

    ; Use this to trap breakpoints in "unknown" banks. Just "jsr catch" from wherever you want
    ; to catch the code, and put a breakpoint here instead. Then step, and you're at the place
    ; you wanted to see, without knowing the bank.

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

                    PHASE AI_FlipBuffers

                    JSROM_SAFE CastleFixup


    ; Handle en-passant captures
    ; The (dual-use) FLAG_ENPASSANT will have been cleared if it was set for a home-rank move
    ; but if we're here and the flag is still set, then it's an actual en-passant CAPTURE and we
    ; need to do the appropriate things...


    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

                    ldy enPassantPawn               ; save

                    ldx #0
                    lda fromPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    lda fromPiece
                    and #~FLAG_ENPASSANT            ; clear flag as it's been handled
                    sta fromPiece

                    ldx fromX12                       ; this IS an en-passantable opening, so record the square
.noep               stx enPassantPawn               ; capturable square for en-passant move


    ; ^


    ; Check to see if we are doing an actual en-passant capture...

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    beq .noEP


#if 1

capture

    IF ASSERTS
                    cpy #0
.eperror            beq .eperror                    ; CANNOT have EP *AND* no capture square!!
    ENDIF

            lda sideToMove
            eor #128
            sta sideToMove



                    sty fromX12
                    sty drawPieceNumberX12

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

            lda sideToMove
            eor #128
            sta sideToMove

    #endif



.noEP

    ; Mark the piece as MOVED

                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    ldy fromX12                     ; final square
                    lda Board,y
                    and #~FLAG_ENPASSANT
                    ora #FLAG_MOVED
                    sta Board+RAM_WRITE,y




#if ASSERTS
                    JSROM_SAFE DIAGNOSTIC_checkPieces
#endif


                    lda sideToMove
                    eor #128
                    sta sideToMove

                    rts


;---------------------------------------------------------------------------------------------------

    DEF MoveForSinglePiece
    SUBROUTINE

        VAR __vector, 2

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

                    lda #RAMBANK_MOVES_RAM      ; 2         ; TODO: NOT NEEDED IF FIXED BANK CALLED THIS
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


                    lda #0
                    sta enPassantPawn               ; no en-passant


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

#if 0
    ; Add the material value of the piece to the material score

                    cmp #128                        ; CC=white, CS=black
                    and #PIECE_MASK
                    tay

                    JSROM AddPieceMaterialValue

                    txa
                    pha

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy InitPieceList+1,x           ; square


                    lda InitPieceList,x             ; type

                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK


                    jsr AddPiecePositionValue

                    pla
                    tax

    ; ^
#endif

                    lda #BANK_PieceValueLO
                    sta SET_BANK

                    lda PieceValueHI,y
                    pha
                    lda PieceValueLO,y
                    pha

                    lda InitPieceList,x             ; colour/-1
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
                    bpl .fillPieceLists

.finish

#if 0

    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM

                    ldx #15
.scan               lda PieceSquare,x
                    beq .dead

                    clc
                    lda Evaluation
                    adc PieceMaterialValueLO,x
                    sta Evaluation
                    lda Evaluation+1
                    adc PieceMaterialValueHI,x
                    sta Evaluation+1

.dead               dex
                    bpl .scan

    SUBROUTINE

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM

                    ldx #15
.scan               lda PieceSquare,x
                    beq .dead

                    sec
                    lda Evaluation
                    sbc PieceMaterialValueLO,x
                    sta Evaluation
                    lda Evaluation+1
                    sbc PieceMaterialValueHI,x
                    sta Evaluation+1

.dead               dex
                    bpl .scan

#endif

                    rts


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



    DEF GetBoard
                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK
                    rts

    DEF PutBoard
                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM
                    sta Board+RAM_WRITE,y           ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF SAFE_IsValidMoveFromSquare
    SUBROUTINE

    ; Does the square exist in the movelist?

                    ldx cursorX12
                    stx aiFromSquareX12
                    txa

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

                    ldy cursorX12
                    sty aiToSquareX12
                    tya

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListToSquare

.found              lda savedBank
                    sta SET_BANK
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
                    rts


;---------------------------------------------------------------------------------------------------

    DEF PromoteStart
    SUBROUTINE

        ; Remove any piece on the promotion square while we do the promotion selection

                    jsr GetBoard
                    and #PIECE_MASK
                    beq .nopiece

    DEF SAFE_CopySinglePiece

                    jsr CopySinglePiece
.nopiece            lda savedBank
                    sta SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE
    TIMING COPYSINGLEPIECE, 2150

    ; WARNING: CANNOT USE VAR/OVERLAY IN ANY ROUTINE CALLING THIS!!
    ; ALSO CAN'T USE IN THIS ROUTINE
    ; This routine will STOMP on those vars due to __pieceShapeBuffer occupying whole overlay


    ; @2150 max
    ; = 33 TIM64T


                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM
                    jsr CopySetup


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

                    lda drawPieceNumberX12
                    sec
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    stx SET_BANK_RAM

                    adc #8
                    cmp #4

                    jmp CopyPieceToRowBitmap


;---------------------------------------------------------------------------------------------------

    DEF SAFE_getMoveIndex
    SUBROUTINE

                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    lda moveIndex
                    ldx savedBank
                    stx SET_BANK
                    rts


    DEF GoFixPieceList
                    sta SET_BANK_RAM
                    jsr FixPieceList
                    lda savedBank
                    sta SET_BANK
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

                    dec aiMoveIndex

                    lda #RAMBANK_PLY                ; current player
                    sta SET_BANK_RAM

                    lda MoveFrom,x
                    cmp aiFromSquareX12
                    bne .next

                    ldy MoveTo,x

    ; If it's a pawn promote (duplicate "to" AND piece different (TODO) then skip others)

                    tya
.sk                 dex
                    bmi .prom
                    cmp MoveTo,x
                    bne .prom

                    dec aiMoveIndex
                    dec aiMoveIndex
                    dec aiMoveIndex
.prom



                    lda #RAMBANK_MOVES_RAM
                    sta SET_BANK_RAM

                    lda Board,y
                    bne .next                       ; don't draw dots on captures - they are flashed later

                    sty drawPieceNumberX12

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    jsr CopySetupForMarker
                    jsr InterceptMarkerCopy

.skip               lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_showPromoteOptions
    SUBROUTINE

    ; Pass          X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty drawPieceNumberX12

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

    DEF GetMoveTo
                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda MoveTo,x
                    sty SET_BANK
                    rts

    DEF GetMovePiece
                    lda #RAMBANK_PLY
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda MovePiece,x
                    sty SET_BANK
                    rts


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
