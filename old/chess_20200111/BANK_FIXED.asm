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

    DEFINE_SUBROUTINE ClearChessBitmap

                ldx #7              ; row #
.clearRow       stx SET_BANK_RAM
                jsr ClearRowBitmap
                dex
                bpl .clearRow
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE CopyChessboardPiecesToBoard



                lda #BANK_CHESSBOARD
                sta SET_BANK_RAM

                ldy #63
.drawPieces
                tya
                pha

                lda BoardPiece,y
                tay
                jsr CopyPieceToRAMBuffer

                pla
                pha

                lsr
                lsr
                lsr
                tax             ; row

                pla
                pha
                and #4
                cmp #4                      ; cc = left side, cs = right side
                jsr CopyPieceFromRAMBufferToScreen

                pla
                tay
                dey
                bpl .drawPieces

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

BoardPiece

    .byte INDEX_BLACK_ROOK_on_WHITE_SQUARE_0 ;0
    .byte INDEX_BLACK_KNIGHT_on_BLACK_SQUARE_1 ;1
    .byte INDEX_BLACK_BISHOP_on_WHITE_SQUARE_2 ;2
    .byte INDEX_BLACK_QUEEN_on_BLACK_SQUARE_3 ;3
    .byte INDEX_BLACK_KING_on_WHITE_SQUARE_0 ;4
    .byte INDEX_BLACK_BISHOP_on_BLACK_SQUARE_1 ;5
    .byte INDEX_BLACK_KNIGHT_on_WHITE_SQUARE_2 ;6
    .byte INDEX_BLACK_ROOK_on_BLACK_SQUARE_3 ;7

    .byte INDEX_BLACK_PAWN_on_BLACK_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_1
    .byte INDEX_BLACK_PAWN_on_BLACK_SQUARE_2
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_3
    .byte INDEX_BLACK_PAWN_on_BLACK_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_1
    .byte INDEX_BLACK_PAWN_on_BLACK_SQUARE_2
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_3

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_3
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_3

    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_3
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_3

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_3
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_3

    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_3
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_BLANK_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_3

    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_PAWN_on_BLACK_SQUARE_3
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_BLACK_SQUARE_1
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_2
    .byte INDEX_WHITE_PAWN_on_BLACK_SQUARE_3

    .byte INDEX_WHITE_ROOK_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_BISHOP_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_3
    .byte INDEX_WHITE_KING_on_BLACK_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_1
    .byte INDEX_WHITE_KNIGHT_on_BLACK_SQUARE_2
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_3


;---------------------------------------------------------------------------------------------------


    DEFINE_SUBROUTINE CopyPieceFromRAMBufferToScreen

    ; we have a ~1K RAM screen
    ; x = row
    ; y = line*24-1

                stx SET_BANK_RAM
                jmp CopyPieceToRowBitmap

    ;-----------------------------------------------------------------------------------------------

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

    ;------------------------------------------------------------------------------


    DEFINE_SUBROUTINE TimeSlice

    ; FIRST check the time is sufficient for the smallest of the timeslices. Not much point
    ; going ahead if there's insufficient time. This allows the previous character drawing to
    ; be much smaller in time, as they don't have to include the timeslice code overhead.

                lda INTIM                       ; 4
                cmp #SEGTIME_MINIMUM_TIMESLICE  ; 2
                bcc timeExit                    ; 2(3)
                                                ; @0✅
timeExit        rts

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

                lda #$12
                sta rnd


    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

                ldy #7
.copyRowBanks   ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                jsr CopyShadowROMtoRAM
                dey
                bpl .copyRowBanks

    ; Patch the final row's "loop" to a RTS

                lda #<SELFMOD_RTS_ON_LAST_ROW
                sta __ptr
                lda #>(SELFMOD_RTS_ON_LAST_ROW+RAM_WRITE)
                sta __ptr+1

                lda #7
                sta SET_BANK_RAM

                ldy #0
                lda #$60                        ; rts
                sta (__ptr),y                   ; patch selfmod code to RTS



                jsr InitialiseChessboard

    ; Now the board is "living" in RAM (along with support code) we can do stuff with it

                jsr ClearChessBitmap


                jsr CopyChessboardPiecesToBoard

                lda #0
                sta SET_BANK_RAM
                jsr DrawTheChessScreen

                ;lda #2
                ;sta VSYNC
                ;lda #%01000010                  ; bit6 is not required
                ;sta VBLANK                      ; end of screen - enter blanking

Restart     ; go here on RESET + SELECT

                jmp Reset


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
