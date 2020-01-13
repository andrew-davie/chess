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

                ldx doubleBufferBase
    REPEAT 4
                stx SET_BANK_RAM
                jsr ClearRowBitmap
                inx
    REPEND
                rts

    DEFINE_SUBROUTINE ClearChessBitmap_PART1

                lda doubleBufferBase
                ora #4
                tax
    REPEAT 4
                stx SET_BANK_RAM
                jsr ClearRowBitmap
                inx
    REPEND
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
                eor #1
                beq .white
                lda #28
.white          sta __pieceColour           ; actually SQUARE black/white

                ldy drawPieceNumber
                tya
                and #3
                ora Chessboard,y
                sec
                sbc __pieceColour
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

    DEFINE_SUBROUTINE RandomPieceMove

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM

                NEXT_RANDOM
                tax
.nextX          inx
                txa
                and #63
                tax

                lda Chessboard,x
                cmp #BLANK
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
                cmp #BLANK
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
                and #~3
                sta Chessboard+RAM_WRITE,x
                dex
                bpl .setupBoard

                rts

BoardPiece

BLANK = INDEX_WHITE_BLANK_on_BLACK_SQUARE_0
WHITE_PAWN = INDEX_WHITE_PAWN_on_BLACK_SQUARE_0
WHITE_ROOK = INDEX_WHITE_ROOK_on_BLACK_SQUARE_0
WHITE_KNIGHT = INDEX_WHITE_KNIGHT_on_BLACK_SQUARE_0
WHITE_BISHOP = INDEX_WHITE_BISHOP_on_BLACK_SQUARE_0
WHITE_QUEEN = INDEX_WHITE_QUEEN_on_BLACK_SQUARE_0
WHITE_KING = INDEX_WHITE_KING_on_BLACK_SQUARE_0
BLACK_PAWN = INDEX_BLACK_PAWN_on_BLACK_SQUARE_0
BLACK_ROOK = INDEX_BLACK_ROOK_on_BLACK_SQUARE_0
BLACK_KNIGHT = INDEX_BLACK_KNIGHT_on_BLACK_SQUARE_0
BLACK_BISHOP = INDEX_BLACK_BISHOP_on_BLACK_SQUARE_0
BLACK_QUEEN = INDEX_BLACK_QUEEN_on_BLACK_SQUARE_0
BLACK_KING = INDEX_BLACK_KING_on_BLACK_SQUARE_0


    .byte BLACK_ROOK ;0
    .byte BLACK_KNIGHT ;1
    .byte BLACK_BISHOP ;2
    .byte BLACK_QUEEN ;3
    .byte BLACK_KING ;4
    .byte BLACK_BISHOP ;5
    .byte BLACK_KNIGHT ;6
    .byte BLACK_ROOK ;7

    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN
    .byte BLACK_PAWN

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

    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN
    .byte WHITE_PAWN

    .byte WHITE_ROOK
    .byte WHITE_KNIGHT
    .byte WHITE_BISHOP
    .byte WHITE_QUEEN
    .byte WHITE_KING
    .byte WHITE_BISHOP
    .byte WHITE_KNIGHT
    .byte WHITE_ROOK


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
.copyPieceGfx   lda (__ptr),y
                sta __pieceShapeBuffer,y
                dey
                bpl .copyPieceGfx

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

                lda #$92
                sta rnd


    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                ldy #15
.copyRowBanks   ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                jsr CopyShadowROMtoRAM
                dey
                bpl .copyRowBanks

    ; Patch the final row's "loop" to a RTS

                lda #<SELFMOD_RTS_ON_LAST_ROW
                sta __ptr
                lda #>(SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE)
                sta __ptr+1


                ldy #0
                lda #$60                        ; rts

    ; the 'screen' is double-buffered - two sets of 8x1K banks
    ; we need to put an RTS on the last of both of these

                ldx #7
                stx SET_BANK_RAM
                sta (__ptr),y                   ; patch selfmod code to RTS

                ldx #15
                stx SET_BANK_RAM
                sta (__ptr),y


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



;                lda INPT4
;                bpl .ret

;                jmp .RestartChessFrame

;.ret

                jmp .doubleBufferLoop

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

DrawVectorLO
    .byte <Phase0_ClearBoard_0
    .byte <Phase0_ClearBoard_1
    .byte <DrawNextPiece
    .byte <FlipBuffers
    .byte <EraseStartPiece
    .byte <WriteStartPieceBlank
    .byte <MarchToTargetA
    ;.byte <DelayIt
    .byte <MarchToTargetB
    .byte <WriteEndPieceBlank
    .byte <WriteEndPiece
    .byte <DelayIt
    .byte <Final

DrawVectorHI
    .byte >Phase0_ClearBoard_0
    .byte >Phase0_ClearBoard_1
    .byte >DrawNextPiece
    .byte >FlipBuffers
    .byte >EraseStartPiece
    .byte >WriteStartPieceBlank
    .byte >MarchToTargetA
    ;.byte >DelayIt
    .byte >MarchToTargetB
    .byte >WriteEndPieceBlank
    .byte >WriteEndPiece
    .byte >DelayIt
    .byte >Final

    DEFINE_SUBROUTINE Phase0_ClearBoard_0

                jsr ClearChessBitmap_PART0
                inc drawPhase
                rts

    DEFINE_SUBROUTINE Phase0_ClearBoard_1

                jsr ClearChessBitmap_PART1

                lda #63
                sta drawPieceNumber

                inc drawPhase
                rts

    DEFINE_SUBROUTINE DrawNextPiece

                jsr CopySinglePiece
                dec drawPieceNumber
                bpl .incomplete

                inc drawPhase
.incomplete     rts

    ; Now we've finished drawing the screen square by square.

    DEFINE_SUBROUTINE FlipBuffers

                jsr RandomPieceMove
                inc drawPhase
                rts

    DEFINE_SUBROUTINE EraseStartPiece

                lda fromSquare
                sta drawPieceNumber
                jsr CopySinglePiece      ; erase the existing piece

                inc drawPhase
                rts

    DEFINE_SUBROUTINE WriteStartPieceBlank

                ldx fromSquare
                stx drawPieceNumber

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                lda #BLANK
                sta Chessboard+RAM_WRITE,x                            ; put a blank on the board

                jsr CopySinglePiece          ; now draw the 'blank' square

                inc drawPhase
                rts

    DEFINE_SUBROUTINE MarchToTargetA

                lda fromSquare
                cmp toSquare
                beq .halt

                lda fromSquare
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



                lda fromSquare

;                clc
;                adc #1
;                and #63
;                sta fromSquare
                tax
                stx drawPieceNumber

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                lda Chessboard,x
                sta lastPiece
                lda fromPiece
                sta Chessboard+RAM_WRITE,x
                jsr CopySinglePiece

                lda #3
                sta drawDelay
                inc drawPhase
                rts

    DEFINE_SUBROUTINE MarchToTargetB

                lda drawDelay
                beq gogogo
                dec drawDelay
                jmp bypass
gogogo

                ldx fromSquare
                stx drawPieceNumber
                jsr CopySinglePiece
                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                ldx fromSquare
                lda lastPiece
                sta Chessboard+RAM_WRITE,x

                dec drawPhase
bypass          rts

.halt           inc drawPhase
                inc drawPhase

    DEFINE_SUBROUTINE WriteEndPieceBlank

                ldx toSquare
                stx drawPieceNumber
                jsr CopySinglePiece          ; now erase the destination square

                inc drawPhase
                rts

    DEFINE_SUBROUTINE WriteEndPiece

                ldx toSquare
                stx drawPieceNumber

                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM
                lda fromPiece
                sta Chessboard+RAM_WRITE,x                            ; put a blank on the board

                jsr CopySinglePiece

                lda #10
                sta drawDelay
                inc drawPhase
                rts

    DEFINE_SUBROUTINE DelayIt

                dec drawDelay
                bne .waiting
                inc drawPhase
.waiting        rts

    DEFINE_SUBROUTINE Final

                lda #3
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
