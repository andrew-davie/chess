
    SLOT 2
    NEWBANK BITMAP

; These equates allow revectoring (address offset) if the RAM slot is not the same as the SHADOW slot

ChessBitmap = SHADOW_ChessBitmap

ChessBitmap0 = SHADOW_ChessBitmap0
ChessBitmap1 = SHADOW_ChessBitmap1
ChessBitmap2 = SHADOW_ChessBitmap2
ChessBitmap3 = SHADOW_ChessBitmap3
ChessBitmap4 = SHADOW_ChessBitmap4
ChessBitmap5 = SHADOW_ChessBitmap5

; Template bank for a SINGLE ROW of the chessboard display.
; There are 8x of these.
; The bank contains the definition of the bitmap, and also the code to draw the bitmap
; The bank is copied from ROM into RAM at startup.
; The draw switches between consecutive row banks, with the last returning
; we effectively have 1K
;---------------------------------------------------------------------------------------------------

COLOUR_LINE_1 = $82
COLOUR_LINE_2 = $36
COLOUR_LINE_3 = $28
BACKGCOL      = $00


ROW_BITMAP_SIZE = 6 * 24            ; PF0/PF1/PF2/(PF0)/(PF1)/(PF2) x 8 ICC pixels


        ALLOCATE SHADOW_ChessBitmap, ROW_BITMAP_SIZE
SHADOW_ChessBitmap0    ds 24
SHADOW_ChessBitmap1    ds 24
SHADOW_ChessBitmap2    ds 24
SHADOW_ChessBitmap3    ds 24
SHADOW_ChessBitmap4    ds 24
SHADOW_ChessBitmap5    ds 24

    ALLOCATE BlankSprite, 8
    ds 8, 0

    ALLOCATE SpriteBuffer, 8
SpriteBuffer2
        .byte %11111000
        .byte %11111000
        .byte %11111000
        .byte %11111000
        .byte %11111000
        .byte %11111000
        .byte %11111000
        .byte %11111000

    IF 0
    ALLOCATE BackupBitmap, ROW_BITMAP_SIZE
    ds ROW_BITMAP_SIZE, 0
    ENDIF

;---------------------------------------------------------------------------------------------------

    ALIGN 256
    SUBROUTINE

    REFER StartupBankReset
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

    CHECK_RAM_BANK_SIZE "ROM_SHADOW_SCREEN"

;---------------------------------------------------------------------------------------------------
;EOF