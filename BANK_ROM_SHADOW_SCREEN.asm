
                NEWBANK BANK_ROM_SHADOW_OF_CHESS_BITMAP

; Template bank for a SINGLE ROW of the chessboard display.
; There are 8x of these.
; The bank contains the definition of the bitmap, and also the code to draw the bitmap
; The bank is copied from ROM into RAM at startup.
; The draw switches between consecutive row banks, with the last returning
; we effectively have 1K
;---------------------------------------------------------------------------------------------------

COLOUR_LINE_1 = $94
COLOUR_LINE_2 = $4a
COLOUR_LINE_3 = $fa
BACKGCOL      = $00

;COLOUR_LINE_1 = $94
;COLOUR_LINE_2 = $48
;COLOUR_LINE_3 = $2C
;BACKGCOL      = $00

;

; good/contrast
;COLOUR_LINE_1 = $a6
;COLOUR_LINE_2 = $4a
;COLOUR_LINE_3 = $2A

;COLOUR_LINE_1 = $94 ; square col
;COLOUR_LINE_2 = $C6
;COLOUR_LINE_3 = $48
;BACKGCOL      = 0 ;$F0


; good 94/46/28/0
; good 94/44/26/0


ROW_BITMAP_SIZE = 6 * 24            ; PF0/PF1/PF2/(PF0)/(PF1)/(PF2) x 8 ICC pixels


    ALLOCATE ChessBitmap, ROW_BITMAP_SIZE
ChessBitmap0    ds 24
ChessBitmap1    ds 24
ChessBitmap2    ds 24
ChessBitmap3    ds 24
ChessBitmap4    ds 24
ChessBitmap5    ds 24

    ALLOCATE BlankSprite, 8
    ds 8, 0

    ALLOCATE SpriteBuffer, 24
SpriteBuffer2
    REPEAT 24
        .byte %11111000
    REPEND

    ALLOCATE BackupBitmap, ROW_BITMAP_SIZE
    ds ROW_BITMAP_SIZE, 0

;---------------------------------------------------------------------------------------------------

    DEF ClearRowBitmap
    SUBROUTINE

        REFER CallClear
        VEND ClearRowBitmap

            ; No transient variable dependencies/calls

                    lda #0
                    ldy #ROW_BITMAP_SIZE
.clearRow           sta@RAM ChessBitmap-1,y
                    dey
                    bne .clearRow
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopyPieceToRowBitmap
    SUBROUTINE

        REFER CopySinglePiece           ; special-case due to 'intercept'
        VEND CopyPieceToRowBitmap

                    ldy #17
                    bcs .rightSide

.copyPiece          lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap,y
                    sta@RAM ChessBitmap,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+18,y
                    sta@RAM ChessBitmap+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+36,y
                    sta@RAM ChessBitmap+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+54,y
                    sta@RAM ChessBitmap+54,y

.blank4             dey
                    bpl .copyPiece
                    rts

.rightSide

    SUBROUTINE

.copyPieceR         lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap+72,y
                    sta@RAM ChessBitmap+72,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+72+18,y
                    sta@RAM ChessBitmap+72+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+72+36,y
                    sta@RAM ChessBitmap+72+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+72+54,y
                    sta@RAM ChessBitmap+72+54,y

.blank4             dey
                    bpl .copyPieceR
                    rts


;---------------------------------------------------------------------------------------------------

    ALIGN 256
    SUBROUTINE

    REFER Reset
__dummy
    VEND __dummy

    ; x = row # (and bank#)

.endline

    ;@59

    ; The following 'inx' is replaced in the LAST row bank with a 'RTS', thus ending the draw loop
    ; Note that the other 7 row banks are unmodified (keeping the 'inx')
SELFMOD_RTS_ON_LAST_ROW

                    inx                         ; 2
                    stx SET_BANK_RAM            ; 3 @64     BANK switch to next row

    DEF DrawRow

 ;@64
                    ldy #7                      ; 2
                    bpl .dl2                    ; 3   (must be 69 here)

    ;@58...

.l3

SMSPRITE16_0        lda SpriteBuffer+16,y       ; 4
                    sta GRP0                    ; 3
SMSPRITE16_1        lda SpriteBuffer2+16,y      ; 4
                    sta GRP1                    ; 3

    ;@-4

                    lda #COLOUR_LINE_1 ;#$94                    ; 2
                    sta COLUPF                  ; 3 @1

                    lda ChessBitmap0+16,y       ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap1+16,y       ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap2+16,y       ; 4
                    sta PF2                     ; 3 @22

                    SLEEP 6                     ; 6 @28

                    lda ChessBitmap3+16,y       ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap4+16,y       ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap5+16,y       ; 4
                    sta.w PF2                   ; 4 @50

                    SLEEP 4                     ; 4

                    dey                         ; 2
                    bmi .endline                ; 2 (3)

    ;@57
.drawLine

                    SLEEP 11

.dl2
SMSPRITE0_0         lda SpriteBuffer,y          ; 4
                    sta GRP0                    ; 3
SMSPRITE0_1         lda SpriteBuffer2,y         ; 4
                    sta GRP1                    ; 3

    ;@7

                    lda #COLOUR_LINE_2 ;#$4A                    ; 2
                    sta COLUPF                  ; 3 @12

                    lda ChessBitmap0,y          ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap1,y          ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap2,y          ; 4
                    sta PF2                     ; 3 @33

                    SLEEP 3                     ; 3 @36

                    lda ChessBitmap3,y          ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap4,y          ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap5,y          ; 4
                    sta PF2                     ; 3 @57

                    SLEEP 5

SMSPRITE8_0         lda SpriteBuffer+8,y        ; 4
                    sta GRP0                    ; 3
SMSPRITE8_1         lda SpriteBuffer2+8,y       ; 4
                    sta GRP1                    ; 3

    ;@0
                    lda #COLOUR_LINE_3 ;#$28                    ; 2
                    sta COLUPF                  ; 3 @5

                    lda ChessBitmap0+8,y        ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap1+8,y        ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap2+8,y        ; 4
                    sta PF2                     ; 3 @26

                    SLEEP 8                     ; 6 @34

                    lda ChessBitmap3+8,y        ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap4+8,y        ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap5+8,y        ; 4
                    sta PF2                     ; 3 @55

                    jmp .l3                     ; 3 @58


;---------------------------------------------------------------------------------------------------

    DEF WriteBlank
    SUBROUTINE

        REFER Reset
        VEND WriteBlank

                    lda #<BlankSprite
                    sta@RAM SMSPRITE0_0+1
                    sta@RAM SMSPRITE8_0+1
                    sta@RAM SMSPRITE16_0+1
                    sta@RAM SMSPRITE0_1+1
                    sta@RAM SMSPRITE8_1+1
                    sta@RAM SMSPRITE16_1+1

                    lda #>BlankSprite
                    sta@RAM SMSPRITE0_0+2
                    sta@RAM SMSPRITE8_0+2
                    sta@RAM SMSPRITE16_0+2
                    sta@RAM SMSPRITE0_1+2
                    sta@RAM SMSPRITE8_1+2
                    sta@RAM SMSPRITE16_1+2

                    rts


;---------------------------------------------------------------------------------------------------

    DEF WriteCursor
    SUBROUTINE

        REFER Reset
        VEND WriteCursor

                    sec
                    lda cursorX12
                    bmi .exit
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    stx SET_BANK_RAM
                    lda #<SpriteBuffer
                    sta@RAM SMSPRITE0_0+1
                    sta@RAM SMSPRITE8_0+1
                    sta@RAM SMSPRITE16_0+1
                    lda #>SpriteBuffer
                    sta@RAM SMSPRITE0_0+2
                    sta@RAM SMSPRITE8_0+2
                    sta@RAM SMSPRITE16_0+2

.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF SaveBitmap
    SUBROUTINE

        REFER SAFE_BackupBitmaps
        VEND SaveBitmap

                    ldy #71
.fromTo             lda ChessBitmap,y
                    sta@RAM BackupBitmap,y
                    lda ChessBitmap+72,y
                    sta@RAM BackupBitmap+72,y
                    dey
                    bpl .fromTo
                    rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF RestoreBitmap
    SUBROUTINE

        VEND RestoreBitmap

                    ldy #71
.fromTo             lda BackupBitmap,y
                    sta@RAM ChessBitmap,y
                    lda BackupBitmap+72,y
                    sta@RAM ChessBitmap+72,y
                    dey
                    bpl .fromTo
                    rts
#endif

;---------------------------------------------------------------------------------------------------

#if 0
    DEF CopyTextToRowBitmap
    SUBROUTINE

        VEND CopyTextToRowBitmap

    ; An OR-draw, used for placing matricies/text onscreen
    ; Similar to the EOR - first copy data into __pieceShapeBuffer, then call this function
    ; The draw can be bracketed by "SaveBitmap" and "RestoreBitmap" to leave screen
    ; in original state once text disappears

                    ldy #71
                    bcs .rightSide

.copy               lda __pieceShapeBuffer,y
                    ora ChessBitmap,y
                    sta@RAM ChessBitmap,y
                    dey
                    bpl .copy

                    rts

.rightSide

    SUBROUTINE

.copy               lda __pieceShapeBuffer,y
                    ora ChessBitmap+72,y
                    sta@RAM ChessBitmap+72,y
                    dey
                    bpl .copy

                    rts

#endif

;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "ROM_SHADOW_SCREEN"
    ;VALIDATE_RAM_SIZE
