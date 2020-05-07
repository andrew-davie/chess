
    SLOT 3
    NEWBANK BITMAP2

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

    DEF CopyPieceToRowBitmap;@3
    SUBROUTINE

        ;REFER CopySinglePiece           ; special-case due to 'intercept'
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

    IF 1
    DEF WriteBlank
    SUBROUTINE

        REFER StartupBankReset
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
    ENDIF

;---------------------------------------------------------------------------------------------------

    IF 1
    DEF WriteCursor
    SUBROUTINE

        REFER StartupBankReset
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
    ENDIF


;---------------------------------------------------------------------------------------------------

    IF 0
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
    ENDIF

;---------------------------------------------------------------------------------------------------

    IF 0

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
    ENDIF

;---------------------------------------------------------------------------------------------------

    IF 0

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

    ENDIF

;---------------------------------------------------------------------------------------------------

    CHECK_RAM_BANK_SIZE "ROM_SHADOW_SCREEN"

;---------------------------------------------------------------------------------------------------
;EOF