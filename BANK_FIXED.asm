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

    DEFINE_SUBROUTINE CopySinglePieceB

                pha
                lda #BLACK                  ; just the dots!
                sta Board+RAM_WRITE,y
                pla

                jsr ConvertToBase64
                sty drawPieceNumber

                jsr CopySinglePiece
                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                rts




    DEFINE_SUBROUTINE CopySinglePiece


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

    DEFINE_SUBROUTINE MoveViaList

                lda currentPly
                sta SET_BANK_RAM                ; switch in movelist

                lda moveIndex
                cmp #-1
                beq halted                      ; no valid moves


.another        NEXT_RANDOM
                and #31
                cmp moveIndex
                bcs .another
                tax



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


    DEFINE_SUBROUTINE FinaliseMove

                lda sideToMove
                asl
                adc #RAMBANK_PLY
                sta SET_BANK_RAM

                jsr FixPieceList

                lda toX12
                sta fromX12

                lda #0
                sta toX12                   ; --> deleted (square=0)

                lda sideToMove
                eor #128
                asl
                adc #RAMBANK_PLY
                sta SET_BANK_RAM
                jsr FixPieceList            ; REMOVE any captured object



                lda sideToMove
                eor #128
                sta sideToMove

    ;            lda #RAMBANK_MOVES_RAM
    ;            sta SET_BANK_RAM
    ;            ldx toSquare              ; = destination now
    ;            stx drawPieceNumber

    ;            lda fromPiece
    ;            sta Board+RAM_WRITE,x

    ;            jsr CopySinglePiece

    ;            ldx fromX12
    ;            lda #BLANK
    ;            sta Board+RAM_WRITE,x
    ;            ldx toX12
    ;            lda fromPiece
    ;            sta Board+RAM_WRITE,x

    ; and piecelist

;                lda sideToMove
;                eor #128
;                asl
;                adc #RAMBANK_PLY
;                sta SET_BANK_RAM

;                lda toX12
;                sta fromX12
;                lda #0
;                sta toX12
    ;            jsr FixPieceList                ; delete piece if in opposition list

                rts


#if 0
DELX = 50

Move

    ; numbering is BASE64

            .byte WHITE|WPAWN,12,12+16,DELX ; e2e4
            ;.byte BLACK|BPAWN,51,51-16,DELX ; d7d5
            ;.byte WHITE|KNIGHT,6,21,DELX ; g1f3
            ;.byte BLACK|BPAWN,35,28,DELX ;d5e4
            ;.byte WHITE|KNIGHT,21,38,DELX ;f3-g5
            ;.byte BLACK|BPAWN,53,37,DELX ;f7f5
            ;.byte WHITE|B,5,26,DELX ;f1c4
            ;.byte BLACK|N,57,42,DELX ;b8c6
            ;.byte WHITE|KNIGHT,38,53,DELX ;f3-g5
            ;.byte WHITE|KING,4,4,DELX


            .byte WHITE|QUEEN,3,21,DELX
            .byte WHITE|QUEEN,21,17,DELX
            .byte WHITE|QUEEN,17,41,DELX
            .byte WHITE|QUEEN,41,46,DELX
            .byte WHITE|QUEEN,46,30,DELX
            .byte WHITE|KING,4,4,255
            .byte 0
#endif

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE ConvertToBase64
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

    DEFINE_SUBROUTINE InitialiseChessboard

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

    DEFINE_SUBROUTINE CopyPieceToRAMBuffer

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

    DEFINE_SUBROUTINE CopyShadowROMtoRAM
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

    DEFINE_SUBROUTINE Reset

                CLEAN_START

                lda #BANK_TitleScreen
                sta SET_BANK
                ;jsr TitleScreen


                lda #$9A
                sta rnd
                lda #0
                sta movePointer

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


                lda currentPly
                sta SET_BANK_RAM
                jsr NewPlyInitialise                ; must be called at the start of every new ply




                jsr InitialiseChessboard

    ; Now the board is "living" in RAM (along with support code) we can do stuff with it

                lda #0
                sta doubleBufferBase
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

                ldx doubleBufferBase
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

    DEFINE_SUBROUTINE PhasedProcessor

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
;    .byte <ClearTracks
;    .byte <ClearTracksB

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
;    .byte >ClearTracks
;    .byte >ClearTracksB
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

    DEFINE_SUBROUTINE StartClearBoard

                ldx #8
                stx drawCount               ; = bank
                inc drawPhase

    DEFINE_SUBROUTINE ClearEachRow

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

    DEFINE_SUBROUTINE DrawEntireBoard

                jsr CopySinglePiece
                dec drawPieceNumber
                bpl .incomplete

                inc drawPhase
.incomplete     rts


; NOTE: to draw "track" set the blank square tO BLACK


    ; Now we've finished drawing the screen square by square.

    DEFINE_SUBROUTINE FlipBuffers

                lda enPassantSquare                 ; potentially set by move in previous ply
                sta enPassantPawn                   ; grab enPassant flag from PLY for later checking

                lda currentPly
                sta SET_BANK_RAM
                jsr NewPlyInitialise                ; zap movelist for this ply

                inc drawPhase
                rts


    DEFINE_SUBROUTINE FB0

                lda currentPly
                sta SET_BANK_RAM
                jsr GenerateMovesForAllPieces

                lda piecelistIndex
                and #15
                cmp #15
                bne .waitgen

                inc drawPhase
.waitgen        rts


    DEFINE_SUBROUTINE FB2

                jsr MoveViaList
                inc drawPhase
                rts

    DEFINE_SUBROUTINE FB3

                jsr FinaliseMove

                lda #BLANK
                sta previousPiece

                inc drawPhase
;                rts


    DEFINE_SUBROUTINE EraseStartPiece


                lda #6                  ; on/off count
                sta drawCount           ; flashing for piece about to move
                lda #0
                sta drawDelay

                inc drawPhase


    DEFINE_SUBROUTINE WriteStartPieceBlank

                lda drawDelay
                beq deCount
                dec drawDelay
                rts

deCount         lda drawCount
                beq flashDone
                dec drawCount

                lda #6
                sta drawDelay               ; "getting ready to move" flash

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece
                rts

flashDone       inc drawPhase


    DEFINE_SUBROUTINE MarchToTargetA

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
                jsr CopySinglePiece             ; erase destination--> blank

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

MarchB          lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw the moving piece into the new square

                lda #6                          ; snail trail delay
                sta drawDelay

                inc drawPhase
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE MarchToTargetB

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

    DEFINE_SUBROUTINE MarchB2

                lda lastSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw previous piece back in old position

                lda fromSquare
                cmp toSquare
                beq xhalt

                lda #1            ; inter-move segment speed (can be 0)
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


                lda #6                  ; on/off count
                sta drawCount           ; flashing for piece about to move
                lda #0
                sta drawDelay

                inc drawPhase
                rts


    DEFINE_SUBROUTINE FinalFlash

                lda drawDelay
                beq .deCount
                dec drawDelay
                rts

.deCount         lda drawCount
                beq flashDone2
                dec drawCount

                lda #3
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

    ; todo: fixpiecesquare!!!!! for rook or will this be auto?

    ;            lda #RAMBANK_MOVES_RAM
    ;            sta SET_BANK_RAM
    ;            lda Board,y
    ;            sta fromPiece

                lda #CSL
                sta drawPhase
                rts



.noCast

                lda #STARTMOVE
                sta drawPhase
                rts


;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE MoveForSinglePiece

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM

    ; iterate piecelist
    ; call move generators

                ldy currentSquare
                lda Board,y
                sta currentPiece

                and #PIECE_MASK
                tay

    IF ASSERTS
lock    beq lock                    ; catch errors
    ENDIF

                lda HandlerVectorLO,y
                sta __vector
                lda HandlerVectorHI,y
                sta __vector+1

                ldx currentSquare
                jmp (__vector)

MoveReturn      lda currentPly
                sta SET_BANK_RAM
                rts

;---------------------------------------------------------------------------------------------------

    include "Handler_PAWN.asm"
    include "Handler_KING.asm"

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE AddMove

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

                ldx moveIndex
                inx
                stx moveIndex+RAM_WRITE

                lda currentSquare
                sta MoveFrom+RAM_WRITE,x
                lda currentPiece
                sta MovePiece+RAM_WRITE,x
                tya
                sta MoveTo+RAM_WRITE,x
                tax

                lda #RAMBANK_MOVES_RAM
                sta SET_BANK_RAM
                rts

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
