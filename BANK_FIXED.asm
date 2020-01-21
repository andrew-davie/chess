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

STELLA_AUTODETECT .byte $85,$3e,$a9,$00

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE ClearChessBitmap_PART0

                rts

    DEFINE_SUBROUTINE ClearChessBitmap_PART1
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE CopySinglePiece

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM

                lda drawPieceNumber
                lsr
                lsr
                lsr
                clc
                adc drawPieceNumber
                and #1
                ;eor #1
                beq .white
                lda #28
.white          sta __pieceColour           ; actually SQUARE black/white

    ; PieceColour = 0 for white square, 28 for black square

                ldy drawPieceNumber


                tya
                and #3          ; shift position in PF

        ldx #BANK_CHESSBOARD
        stx SET_BANK_RAM

                ldx Chessboard,y
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
                ;ora doubleBufferBase
                tax             ; row

                lda drawPieceNumber
                and #4
                cmp #4                      ; cc = left side, cs = right side

                stx SET_BANK_RAM
                jmp CopyPieceToRowBitmap

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE MoveViaList

                ldx movePointer
                lda Move,x
                bmi halted

                lda Move+1,x
                sta fromSquare
                tay
                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                lda Move,x ;Chessboard,y
                sta fromPiece
                lda Move+2,x
                sta toSquare

    lda Move+3,x
;    beq zz
;    NEXT_RANDOM
;    and #31
;    adc Move+2,x
;    asl
zz                sta drawDelay
                inx
                inx
                inx
                inx
                stx movePointer


halted          rts

DELX = 50

Move

            .byte WHITE|ROOK,20,63,0 ; e2e4
            .byte WHITE|KNIGHT,20,62,0 ; e2e4
            .byte WHITE|BISHOP,20,61,0 ; e2e4
            .byte WHITE|KING,20,60,0 ; e2e4
            .byte WHITE|QUEEN,20,59,0 ; e2e4
            .byte WHITE|BISHOP,20,58,0 ; e2e4
            .byte WHITE|KNIGHT,20,57,0 ; e2e4
            .byte WHITE|ROOK,20,56,0 ; e2e4

            .byte WHITE|PAWN,20,55,0 ; e2e4
            .byte WHITE|PAWN,20,54,0 ; e2e4
            .byte WHITE|PAWN,20,53,0 ; e2e4
            .byte WHITE|PAWN,20,52,0 ; e2e4
            .byte WHITE|PAWN,20,51,0 ; e2e4
            .byte WHITE|PAWN,20,50,0 ; e2e4
            .byte WHITE|PAWN,20,49,0 ; e2e4
            .byte WHITE|PAWN,20,48,0 ; e2e4

            .byte BLACK2|ROOK,43,0,0 ; e2e4
            .byte BLACK2|KNIGHT,43,1,0 ; e2e4
            .byte BLACK2|BISHOP,43,2,0 ; e2e4
            .byte BLACK2|QUEEN,43,3,0 ; e2e4
            .byte BLACK2|KING,43,4,0 ; e2e4
            .byte BLACK2|BISHOP,43,5,0 ; e2e4
            .byte BLACK2|KNIGHT,43,6,0 ; e2e4
            .byte BLACK2|ROOK,43,7,0 ; e2e4

            .byte BLACK2|PAWN,43,8,0 ; e2e4
            .byte BLACK2|PAWN,43,9,0 ; e2e4
            .byte BLACK2|PAWN,43,10,0 ; e2e4
            .byte BLACK2|PAWN,43,11,0 ; e2e4
            .byte BLACK2|PAWN,43,12,0 ; e2e4
            .byte BLACK2|PAWN,43,13,0 ; e2e4
            .byte BLACK2|PAWN,43,14,0 ; e2e4
            .byte BLACK2|PAWN,43,15,0 ; e2e4



            .byte WHITE|PAWN,52,52-16,DELX ; e2e4
            .byte BLACK2|PAWN,11,11+16,DELX ; d7d5
            .byte WHITE|KNIGHT,62,62-17,DELX ; g1f3
            .byte BLACK2|PAWN,27,27+9,DELX ;d5e4
            .byte WHITE|KNIGHT,45,45-15,DELX ;f3-g5
            .byte BLACK2|PAWN,13,13+16,DELX ;f7f5
            .byte WHITE|BISHOP,61,61-3*8-3,DELX ;f1c4
            .byte BLACK2|KNIGHT,1,1+17,DELX  ;b8c6
            .byte WHITE|KING,60,62,DELX   ;0-0
            .byte WHITE|ROOK,63,61,0
            .byte BLACK2|KNIGHT,6,6+15,DELX ;g8f6
            .byte WHITE|KNIGHT,30,20,DELX ;g5e6
            .byte BLACK2|QUEEN,3,3+16,DELX ;D8d6
            .byte WHITE|KNIGHT,20,20-15,DELX ;e6f8
            .byte BLACK2|KNIGHT,21,21+17,DELX ;f6g4
            .byte WHITE|KNIGHT,57,42,DELX ;B1C3
            .byte BLACK2|QUEEN,19,55,DELX ;qxp mate


;            .byte 7,5,DELX
;            .byte 51,51-16,DELX
;            .byte 36,43,DELX
;            .byte 35,35,0
;            .byte 59,59-16,DELX
;            .byte 19,19+3*8,DELX
;            .byte 50,43,DELX
;            .byte 18,18+17,DELX
;            .byte 57,57-17,DELX
;            .byte 35,35+17,DELX
;            .byte 62,63,DELX
;            .byte 52,58,DELX
;            .byte 56,58,DELX
;            .byte 21,21+17,DELX
            .byte WHITE|KING,62,62,DELX
            .byte -1



    DEFINE_SUBROUTINE RandomPieceMove

        jmp MoveViaList



                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM

                NEXT_RANDOM
                tax
.nextX          inx
                txa
                and #63
                tax

                lda Chessboard,x
                ;cmp #BLANK
                beq .nextX

                stx fromSquare

                NEXT_RANDOM
                tay
.nextY          iny
                tya
                and #63
                tay


                ;lda #BLANK
                ;sta fromPiece

                lda Chessboard,y
                ;cmp #BLANK
                bne .nextY

                sty toSquare

                lda Chessboard,x
                sta fromPiece

;                sta Chessboard+RAM_WRITE,y
;                lda #BLANK
;                sta Chessboard+RAM_WRITE,x

                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE InitialiseChessboard

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM

                ldx #63
.setupBoard     lda BoardPiece,x
                sta Chessboard+RAM_WRITE,x
                dex
                bpl .setupBoard

                rts


BLACK2 = 8

PieceToShape

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KING_on_WHITE_SQUARE_0
    .byte 0

    .byte INDEX_BLACK_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KING_on_WHITE_SQUARE_0
    .byte 0



BoardPiece

;WHITE_PAWN = INDEX_WHITE_PAWN_on_BLACK_SQUARE_0
;WHITE_ROOK = INDEX_WHITE_ROOK_on_BLACK_SQUARE_0
;WHITE_KNIGHT = INDEX_WHITE_KNIGHT_on_BLACK_SQUARE_0
;WHITE_BISHOP = INDEX_WHITE_BISHOP_on_BLACK_SQUARE_0
;WHITE_QUEEN = INDEX_WHITE_QUEEN_on_BLACK_SQUARE_0
;WHITE_KING = INDEX_WHITE_KING_on_BLACK_SQUARE_0
;BLACK_PAWN = INDEX_BLACK_PAWN_on_BLACK_SQUARE_0
;BLACK_ROOK = INDEX_BLACK_ROOK_on_BLACK_SQUARE_0
;BLACK_KNIGHT = INDEX_BLACK_KNIGHT_on_BLACK_SQUARE_0
;BLACK_BISHOP = INDEX_BLACK_BISHOP_on_BLACK_SQUARE_0
;BLACK_QUEEN = INDEX_BLACK_QUEEN_on_BLACK_SQUARE_0
;BLACK_KING = INDEX_BLACK_KING_on_BLACK_SQUARE_0

    ;.byte BLACK|ROOK ;0
    ;.byte BLACK|KNIGHT ;1
    ;.byte BLACK|BISHOP ;2
    ;.byte BLACK|QUEEN ;3
    ;.byte BLACK|KING ;4
    ;.byte BLACK|BISHOP ;5
    ;.byte BLACK|KNIGHT ;6
    ;.byte BLACK|ROOK ;7

    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN
    ;.byte BLACK|PAWN

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK
    .byte BLANK

    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN
    ;.byte WHITE|PAWN

    ;.byte WHITE|ROOK
    ;.byte WHITE|KNIGHT
    ;.byte WHITE|BISHOP
    ;.byte WHITE|QUEEN
    ;.byte WHITE|KING
    ;.byte WHITE|BISHOP
    ;.byte WHITE|KNIGHT
    ;.byte WHITE|ROOK


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
        REPEAT PIECE_SHAPE_SIZE
                lda (__ptr),y
                sta __pieceShapeBuffer,y
                dey
        REPEND

;.copyPieceGfx   lda (__ptr),y
;                sta __pieceShapeBuffer,y
;                dey
;                bpl .copyPieceGfx

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
                jsr TitleScreen


                lda #$97
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

.VerticalBlank  sta WSYNC
                lda INTIM
                bne .VerticalBlank
                sta VBLANK

                lda doubleBufferBase
                ;eor #8
                tax
                stx SET_BANK_RAM
                jsr DrawRow

                lda #26
                sta TIM64T

                lda #0
                sta PF0
                sta PF1
                sta PF2

                ;jsr PhasedProcessor

    ; D1 VBLANK turns off beam
    ; It needs to be turned on 37 scanlines later

.oscan          lda INTIM
                bne .oscan

                sta WSYNC
                sta WSYNC
;                sta WSYNC
;                sta WSYNC

                lda #%01000010                  ; bit6 is not required
                sta VBLANK                      ; end of screen - enter blanking



                lda INPT4
                bpl .ret
                jmp .doubleBufferLoop

;                jmp .RestartChessFrame

.ret

                ;jmp .doubleBufferLoop

                ;lda #2
                ;sta VSYNC
                ;lda #%01000010                  ; bit6 is not required
                ;sta VBLANK                      ; end of screen - enter blanking

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

MARCH = 6
MARCH_END = 10
STARTMOVE = 3

DrawVectorLO
    .byte <StartClearBoard
    .byte <ClearEachRow
    .byte <DrawEntireBoard
    .byte <FlipBuffers
    .byte <EraseStartPiece
    .byte <WriteStartPieceBlank
    .byte <MarchToTargetA
    .byte <MarchB
    .byte <MarchToTargetB
    .byte <MarchB2

DrawVectorHI
    .byte >StartClearBoard
    .byte >ClearEachRow
    .byte >DrawEntireBoard
    .byte >FlipBuffers
    .byte >EraseStartPiece
    .byte >WriteStartPieceBlank
    .byte >MarchToTargetA
    .byte >MarchB
    .byte >MarchToTargetB
    .byte >MarchB2

    DEFINE_SUBROUTINE StartClearBoard

                ldx #8
                stx drawCount               ; = bank
                inc drawPhase

    DEFINE_SUBROUTINE ClearEachRow

                dec drawCount
                bmi .bitmapCleared
                ldx drawCount
                stx SET_BANK_RAM
                jsr ClearRowBitmap

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

    ; Now we've finished drawing the screen square by square.

    DEFINE_SUBROUTINE FlipBuffers

                jsr RandomPieceMove

                lda #BLANK
                sta previousPiece

                lda drawDelay
                bne normaldraw

                lda #0
                sta snail

                lda #6
                sta drawPhase
                jmp MarchToTargetA

normaldraw
                lda #5
                sta snail

                inc drawPhase

    DEFINE_SUBROUTINE EraseStartPiece


                lda #12
                sta drawCount

                inc drawPhase
                ;rts

    DEFINE_SUBROUTINE WriteStartPieceBlank

                lda drawDelay
                beq deCount
                dec drawDelay
                rts

deCount         lda drawCount
                beq flashDone
                dec drawCount

                lda #5
                sta drawDelay

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece

                dec drawDelay
                rts

flashDone       inc drawPhase
                ;rts


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

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                ldx fromSquare
                lda Chessboard,x
                sta lastPiece                   ; what we are overwriting
                lda fromPiece
                sta Chessboard+RAM_WRITE,x      ; and what'w actually moving there
                inc drawPhase
                rts

MarchB

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw the moving piece into the new square

                lda snail    ; snail trail
                sta drawDelay

                inc drawPhase
                rts

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

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                lda previousPiece
                ldx lastSquare
                sta Chessboard+RAM_WRITE,x

                lda lastPiece
                sta previousPiece

                inc drawPhase
                rts

    DEFINE_SUBROUTINE MarchB2

                lda lastSquare
                sta drawPieceNumber
                jsr CopySinglePiece             ; draw previous piece back in old position

                lda fromSquare
                cmp toSquare
                beq .halt

    ; here we could delay
                ;lda #5            ; inter-move segment speed
                ;sta drawDelay

                lda #MARCH
                sta drawPhase
                rts



.halt           lda #STARTMOVE
                sta drawPhase
                rts


    ;---------------------------------------------------------------------------

    ECHO "FREE BYTES IN FIXED BANK = ", $FFF0 - *

    ;---------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the fixed bank (last 2K of any ROM image in TigerVision)

                SEG PlusCart
                ORG FIXED_BANK + $7F0
                RORG $7FF0
PLUSCART_IO = *
PLUS0 = %10101010
PLUS1 = %00011001
PLUS2 = %10101111
PLUS3 = %00110110
                .byte PLUS0,PLUS1,PLUS2,PLUS3

                SEG InterruptVectors
                ORG FIXED_BANK + $7FC
                RORG $7ffC

;               .word Reset           ; NMI        (not used)
                .word Reset           ; RESET
                .word Reset           ; IRQ        (not used)

    ;---------------------------------------------------------------------------
