; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    ;------------------------------------------------------------------------------
    ;###############################  FIXED BANK  #################################
    ;------------------------------------------------------------------------------

ORIGIN          SET FIXED_BANK

                NEWBANK THE_FIXED_BANK
                RORG $f800


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece


    ; figure colouration of square
                lda drawPieceNumber ;0-63
                lsr
                lsr
                lsr
                clc
                adc drawPieceNumber
                and #1
                eor #1
                beq .white
                lda #28
.white          sta __pieceColour           ; actually SQUARE black/white

    ; PieceColour = 0 for white square, 28 for black square

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                ldy drawPieceNumber         ;0-63
                ldx Base64ToIndex,y

                lda Board,x
                asl
                bcc .blackAdjust
                ora #16
.blackAdjust    lsr
                and #%1111
                tax

                tya
                and #3          ; shift position in PF

                clc
                adc PieceToShape,x
                clc
                adc __pieceColour
                tay
                jsr CopyPieceToRAMBuffer

                lda drawPieceNumber
                lsr
                lsr
                lsr
                eor #7
                ;ora doubleBufferBase
                tax             ; row

                lda drawPieceNumber
                and #4
                cmp #4                      ; cc = left side, cs = right side

                stx SET_BANK_RAM
                jmp CopyPieceToRowBitmap

;---------------------------------------------------------------------------------------------------

    DEF MoveViaList

                lda currentPly
                sta SET_BANK_RAM                ; switch in movelist

                lda moveIndex
                cmp #-1
                beq halted                      ; no valid moves

                tay                             ; loop count
                cpy #0
                beq muldone
                iny

                NEXT_RANDOM

                ldx #0
                lda #0
.mulx           clc
                adc rnd
                bcc .nover
                inx
.nover          dey
                bne .mulx
muldone

; fall through...
;---------------------------------------------------------------------------------------------------

    DEF PhysicallyMovePiece

.foundMove
                lda MoveFrom,x
                sta fromSquare
                sta fromX12
                lda MoveTo,x
                sta toSquare
                sta toX12


    ; If en-passant flag set (pawn doing opening double-move) then record its square as the
    ; en-passant square for the ply.

#if 0
 TODO BANK/BUGGERED AFTER
                lda currentPly
                sta SET_BANK_RAM

                ldy #0
                lda MovePiece,x
                and #ENPASSANT
                beq .notEP
                ldy toSquare
.notEP          sty enPassantSquare+RAM_WRITE

#endif


                lda MovePiece,x
                and #~ENPASSANT                 ;? unsure
                ora #MOVED                      ; piece has now been moved (flag used for castling checks)
                sta fromPiece                   ; MIGHT have castling bit set, which should be handled last


                lda fromSquare
                jsr ConvertToBase64
                sta fromSquare          ;B64

                lda toSquare
                jsr ConvertToBase64
                sta toSquare            ;B64

halted          rts


;---------------------------------------------------------------------------------------------------

    DEF FinaliseMove

    ; Now the visible movement on the board has happened, fix up the pointers to the pieces
    ; for both sides.


                lda sideToMove
                and #128
                asl
                adc #RAMBANK_PLY
                sta SET_BANK_RAM

                jsr FixPieceList

                lda toX12
                sta fromX12                 ; there MAY be no other-side piece at this square - that is OK!
                lda #0
                sta toX12                   ; --> deleted (square=0)

                lda sideToMove
                eor #128
                asl
                adc #RAMBANK_PLY
                sta SET_BANK_RAM

                jsr FixPieceList            ; REMOVE any captured object

    ; And swap sides to move...

                lda sideToMove
                eor #128
                sta sideToMove

                rts

;---------------------------------------------------------------------------------------------------

    DEF ConvertToBase64
    ; uses OVERLAY "Movers"

    ; convert from 10x12 square numbering (0-119) to 8x8 square numbering (0-63)

            sec
            sbc #22

            ldx #$FF
.conv64     sbc #10
            inx
            bcs .conv64
            adc #10

    sta __temp
    txa
    asl
    asl
    asl
    ora __temp
    tay

    ; A = column (0-7)
    ; X = row (0-7)

            rts


;---------------------------------------------------------------------------------------------------

    DEF InitialiseChessboard

                lda #WHITE
                sta sideToMove
                rts

;---------------------------------------------------------------------------------------------------

PieceToShape

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KING_on_WHITE_SQUARE_0

    .byte INDEX_BLACK_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KING_on_WHITE_SQUARE_0


;---------------------------------------------------------------------------------------------------

    DEF CopyPieceToRAMBuffer

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

                rts

;---------------------------------------------------------------------------------------------------

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

    DEF Reset

;                CLEAN_START


                sei
                cld

                ldy INTIM               ; hopefully "random" - preserve it before clearing the machine

                ldx #0
                txa
.CLEAR_STACK    dex
                txs
                pha
                bne .CLEAR_STACK     ; SP=$FF, X = A = Y = 0


    cpy #0
    bne toR
                ldy #$9A
toR                sty rnd


                ;lda #BANK_TitleScreen
                ;sta SET_BANK
                ;jsr TitleScreen


    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                ldy #7
.copyRowBanks   ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                jsr CopyShadowROMtoRAM
                dey
                bpl .copyRowBanks

    ; Patch the final row's "loop" to a RTS

                ldx #7
                stx SET_BANK_RAM
                lda #$60                        ; rts
                sta SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE


    ; copy the BOARD/MOVES bank

                ldy #RAMBANK_MOVES_RAM
                ldx #MOVES
                jsr CopyShadowROMtoRAM              ; this auto-initialises Board too


    ; copy the PLY banks

                lda #MAX_PLY
                sta __plyBank
                ldy #RAMBANK_PLY
                sty currentPly
.copyPlyBanks   ldx #BANK_PLY
                jsr CopyShadowROMtoRAM
                iny
                dec __plyBank
                bne .copyPlyBanks

                lda #RAMBANK_PLY
                sta SET_BANK_RAM
                jsr InitialisePieceSquares


PostInit
                lda currentPly
                sta SET_BANK_RAM
                jsr NewPlyInitialise                ; must be called at the start of every new ply




                jsr InitialiseChessboard

    ; Now the board is "living" in RAM (along with support code) we can do stuff with it

                lda #0
                ;sta doubleBufferBase
                sta drawPhase


                lda #%00000000
                sta CTRLPF
                sta COLUBK


                RESYNC


.doubleBufferLoop

                lda #%1110                       ; VSYNC ON
.loopVSync3     sta WSYNC
                sta VSYNC
                lsr
                bne .loopVSync3                  ; branch until VYSNC has been reset

                ldy #50 ;VBLANK_TIM_NTSC
                sty TIM64T

                jsr PhasedProcessor

;.VB2            lda INTIM
;                bne .VB2
;                sta VBLANK
;




;whoops  bit TIMINT
;    bmi whoops

wait    bit TIMINT
        bpl wait
 lda #0
 sta VBLANK

                ldx #0
                stx SET_BANK_RAM
                jsr DrawRow

                sta WSYNC

                lda #%01000010                  ; bit6 is not required
                sta VBLANK                      ; end of screen - enter blanking

                lda #26
                sta TIM64T

                lda #0
                sta PF0
                sta PF1
                sta PF2


    ; D1 VBLANK turns off beam
    ; It needs to be turned on 37 scanlines later




Waitforit
  BIT TIMINT
  BPL Waitforit

;.oscan          lda INTIM
;                bne .oscan

                sta WSYNC

;                lda #2
;                sta VSYNC
;                lda #%01000010                  ; bit6 is not required
;                sta VBLANK                      ; end of screen - enter blanking

    ; if button pressed, call random - just a bit of added randomness

                lda INPT4
                bmi .nret
                NEXT_RANDOM
.nret

                jmp .doubleBufferLoop


Restart     ; go here on RESET + SELECT

                jmp Reset

;---------------------------------------------------------------------------------------------------

    DEF PhasedProcessor

                ldx drawPhase
                lda DrawVectorLO,x
                sta __ptr
                lda DrawVectorHI,x
                sta __ptr+1
                jmp (__ptr)

MARCH = 9
STARTMOVE = 3
CSL = 6

DrawVectorLO
    .byte <StartClearBoard
    .byte <ClearEachRow
    .byte <DrawEntireBoard
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

DrawVectorHI
    .byte >StartClearBoard
    .byte >ClearEachRow
    .byte >DrawEntireBoard
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

    DEF StartClearBoard

                ldx #8
                stx drawCount               ; = bank
                inc drawPhase

    DEF ClearEachRow

                dec drawCount
                bmi .bitmapCleared
                ldx drawCount
                stx SET_BANK_RAM
                ;jsr ClearRowBitmap

                rts

.bitmapCleared

                lda #63
                sta drawPieceNumber

                inc drawPhase
                rts

    DEF DrawEntireBoard

                jsr CopySinglePiece
                dec drawPieceNumber
                bpl .incomplete

                inc drawPhase
.incomplete     rts


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
                cmp #15
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


                jsr MoveViaList


                inc drawPhase
.halted         rts

;---------------------------------------------------------------------------------------------------

    DEF FB3

                lda #BLANK
                sta previousPiece

                inc drawPhase
;                rts


    DEF EraseStartPiece


                lda #6                  ; on/off count
                sta drawCount           ; flashing for piece about to move
                lda #0
                sta drawDelay

                inc drawPhase

;---------------------------------------------------------------------------------------------------

    DEF WriteStartPieceBlank


    ; Flash the piece in-place preparatory to moving it.
    ; drawDelay = flash speed
    ; drawCount = # of flashes

                lda drawDelay
                beq deCount
                dec drawDelay
                rts

deCount         lda #6
                sta drawDelay               ; "getting ready to move" flash

                lda drawCount
                beq flashDone
                dec drawCount

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece         ; EOR-draw = flash
                rts

flashDone       inc drawPhase

;---------------------------------------------------------------------------------------------------

    DEF MarchToTargetA

    ; Start marching towards destination

                lda drawDelay
                beq .progress
                dec drawDelay
                rts
.progress


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

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; erase next square along --> blank

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                ldx fromSquare
                ldy Base64ToIndex,x

                lda Board,y
                sta lastPiece                   ; what we are overwriting
                lda fromPiece
                and #~CASTLE
                sta Board+RAM_WRITE,y           ; and what's actually moving there
                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

MarchB

    ; Draw the piece in the new square

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw the moving piece into the new square

                lda #6                          ; snail trail delay
                sta drawDelay

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEF MarchToTargetB

                lda drawDelay
                beq .mb
                dec drawDelay
                rts
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

                lda lastSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw previous piece back in old position

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


    DEF FinalFlash

                lda drawDelay
                beq .deCount
                dec drawDelay
                rts

.deCount         lda drawCount
                beq flashDone2
                dec drawCount

                lda #10
                sta drawDelay               ; "getting ready to move" flash

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece
                rts

flashDone2       ;inc drawPhase






    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king

                lda fromPiece
                and #CASTLE
                beq .noCast

                ldx #-1
                lda toSquare
.findCast       inx
                cmp KSquare,x
                bne .findCast

                lda RSquareEnd,x
                sta toX12
                lda RSquareStart64,x
                sta fromSquare
                lda RSquareEnd64,x
                sta toSquare

                ldy RSquareStart,x
                sty fromX12

                lda fromPiece
                and #128
                ora #ROOK
                sta fromPiece

                lda #CSL
                sta drawPhase
                rts



.noCast         lda fromPiece
                and #ENPASSANT
                beq .noEP


    ; TODO - handle the en-passant capture and fixup




.noEP

                jsr checkPieces


                lda #STARTMOVE
                sta drawPhase
                rts


;---------------------------------------------------------------------------------------------------



    DEF MoveForSinglePiece

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

                ldx currentSquare               ; used in move handlers
                lda Board,x
                sta currentPiece

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
    ; do not modify y

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

    DEF checkPieces

                ldx #15
check1          lda #RAMBANK_PLY
                sta SET_BANK_RAM
                ldy PieceSquare,x
                beq .nonehere
                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
.fail           lda Board,y
                beq .fail
                bmi .fail
.nonehere       dex
                bpl check1


                ldx #15
check2          lda #RAMBANK_PLY+1
                sta SET_BANK_RAM
                ldy PieceSquare,x
                beq .nonehere2
                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
.fail2           lda Board,y
                beq .fail2
                bpl .fail2
.nonehere2       dex
                bpl check2

                rts


;---------------------------------------------------------------------------------------------------

    DEF InitialisePieceSquares

    ; Zap the board with the "blank" ROM copy

                ldy #99
.zeroBoard
                ldx #MOVES
                stx SET_BANK
                lda Board,y
                ldx #RAMBANK_MOVES_RAM
                stx SET_BANK_RAM
                sta Board+RAM_WRITE,y
                dey
                bpl .zeroBoard

    ; Initialise the piecelists and the board for the two piecelist banks (BLACK/WHITE)

                ldy #1
.clearb         tya
                clc
                adc #RAMBANK_PLY
                sta SET_BANK_RAM                    ; BLACK/WHITE piecelists
                jsr Inits
                dey
                bpl .clearb

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
FinBoard        rts

;---------------------------------------------------------------------------------------------------

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
