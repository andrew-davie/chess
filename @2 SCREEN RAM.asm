;---------------------------------------------------------------------------------------------------
; @2 SCREEN RAM.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 2
    REPEAT CHESSBOARD_ROWS
        RAMBANK CHESSBOARDROW
        END_BANK
    REPEND


;---------------------------------------------------------------------------------------------------

    ; NOTE: THIS BANK JUST *LOOKS* EMPTY.
    ; It actually contains everything copied from the ROM copy of the ROW RAM banks.
    ; The variable definitions are also in that ROM bank (even though they're RAM :)

    ; Now we have the actual graphics data for each of the rows.  This consists of an
    ; actual bitmap (in exact PF-style format, 6 bytes per line) into which the
    ; character shapes are masked/copied. The depth of the character shapes may be
    ; changed by changing the #LINES_PER_CHAR value.  Note that this depth should be
    ; a multiple of 3, so that the RGB scanlines match at character joins.

    ; We have one bank for each chessboard row.  These banks are duplicates of the above,
    ; accessed via the above labels but with the appropriate bank switched in.

    ROMBANK BITMAP

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

; NTSC

BW = 0
NTSC = 1
PAL =  2



COL_TYPE  = PAL



    IF COL_TYPE = NTSC
COLOUR_LINE_1 = $84
COLOUR_LINE_2 = $44
COLOUR_LINE_3 = $D6
    ENDIF

    IF COL_TYPE = PAL
COLOUR_LINE_1 = $D4 ;86
COLOUR_LINE_2 = $64 ;46
COLOUR_LINE_3 = $36 ;D8
    ENDIF


    IF COL_TYPE = BW
COLOUR_LINE_1 = $24 ;86
COLOUR_LINE_2 = $A2 ;46
COLOUR_LINE_3 = $94 ;D8
    ENDIF


BACKGCOL      = $0

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

;---------------------------------------------------------------------------------------------------

    ;ALIGN 256
    SUBROUTINE

    REF StartupBankReset
;__dummy
;    VEND __dummy

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
                    ldy #7                     ; 2
                    bpl .dl2                    ; 3   (must be 69 here)

    ;@58...

.l3

SMSPRITE16_0        lda SpriteBuffer+16,y       ; 4
                    sta GRP0                    ; 3
SMSPRITE16_1        lda SpriteBuffer2+16,y      ; 4
                    sta GRP1                    ; 3

    ;@-4

SMCOL1              lda #COLOUR_LINE_1 ;#$94                    ; 2
                    sta COLUPF                  ; 3 @1
                    and #$F0
                    lda #$0 ;A0
                    sta COLUBK

                    lda ChessBitmap0+16,y       ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap1+16,y       ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap2+16,y       ; 4
                    sta PF2                     ; 3 @22

                    ;SLEEP 6                     ; 6 @28

                    lda ChessBitmap3+16,y       ; 4
                    sta PF0                     ; 3
                    lda ChessBitmap4+16,y       ; 4
                    sta PF1                     ; 3
                    lda ChessBitmap5+16,y       ; 4
                    sta.w PF2                   ; 4 @50

                    SLEEP 3                     ; 4

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

SMCOL2              lda #COLOUR_LINE_2 ;#$4A                    ; 2
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
SMCOL3              lda #COLOUR_LINE_3 ;#$28                    ; 2
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

    DEF BackupBitmap
    ds ROW_BITMAP_SIZE, 0


;---------------------------------------------------------------------------------------------------

    CHECK_RAM_BANK_SIZE

;---------------------------------------------------------------------------------------------------
;EOF