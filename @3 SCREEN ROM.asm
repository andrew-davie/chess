
    SLOT 3
    ROMBANK ROM_SCREEN

;---------------------------------------------------------------------------------------------------

    DEF ClearRowBitmap
    SUBROUTINE

        REF aiClearEachRow
        VEND ClearRowBitmap

            ; No transient variable dependencies/calls

                    lda #0
                    tay
.clearRow           sta@RAM ChessBitmap,y
                    iny
                    cpy #ROW_BITMAP_SIZE
                    bne .clearRow
                    rts


;---------------------------------------------------------------------------------------------------

    DEF WriteBlank
    SUBROUTINE

        REF StartupBankReset ;✅
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

        REF StartupBankReset ;✅
        VEND WriteCursor

                    sec
                    lda cursorX12
                    bmi .exit
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    txa
                    adc #SLOT_DrawRow               ;cc implied
                    sta SET_BANK_RAM

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

    DEF BackupBitmaps
    SUBROUTINE

    ; drawCount = ROW# (0-7)

        REF aiInCheckBackup
        VEND BackupBitmaps

    ; switch in in ROW bitmap to RAM

                    lda drawCount
                    ora #SLOT2
                    sta SET_BANK_RAM;@2
                    
    ; save bitmap data to backup

                    ldy #0
.fromTo             lda@RAM ChessBitmap,y
                    sta@RAM BackupBitmap,y

                    ;lda #255
                    ;sta@RAM ChessBitmap,y

                    iny
                    cpy #ROW_BITMAP_SIZE
                    bne .fromTo
                    rts


;---------------------------------------------------------------------------------------------------

    DEF RestoreBitmaps
    SUBROUTINE

        VEND RestoreBitmaps

    ; switch in in ROW bitmap to RAM

                    lda drawCount
                    ora #SLOT2
                    sta SET_BANK_RAM;@2

    ; copy backup bitmap back to origin

                    ldy #0
.fromTo             lda@RAM BackupBitmap,y
                    sta@RAM ChessBitmap,y
                    iny
                    cpy #ROW_BITMAP_SIZE
                    bne .fromTo

                    rts


;---------------------------------------------------------------------------------------------------

    IF 0

    DEF CopyTextToRowBitmap
    SUBROUTINE

        VEND CopyTextToRowBitmap

    ; An OR-draw, used for placing matricies/text onscreen
    ; Similar to the EOR - first copy data into __pieceShapeBuffer, then call this function
    ; The draw can be bracketed by "SaveBitmap" and "RestoreBitmap" to leave screen
    ; in original state once text disappears

                    ldy #PIECE_SHAPE_SIZE-1
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
                    ora ChessBitmap+PIECE_SHAPE_SIZE,y
                    sta@RAM ChessBitmap+PIECE_SHAPE_SIZE,y
                    dey
                    bpl .copy

                    rts

    ENDIF

;---------------------------------------------------------------------------------------------------

    DEF aiDrawBitmapBackground
    SUBROUTINE

        REF AiStateMachine
        VAR _tt,1
        VEND aiDrawBitmapBackground

                    dec drawCount
                    bmi .next


                    lda drawCount
                    ora #SLOT2
                    sta SET_BANK_RAM


                    ldx #ROW_BITMAP_SIZE/2-1

.draw               lda SampleBitmap,x
                    and@RAM ChessBitmap,x
                    sta@RAM ChessBitmap,x

                    lda SampleBitmap+ROW_BITMAP_SIZE/2,x
                    and@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x
                    sta@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x

                    dex
                    bpl .draw
                    rts


.next
                    lda #8
                    sta drawCount                   ; ROW

.noButton                    PHASE DrawBitmap2
                    rts

pwb                 PHASE WaitBitmap
                    rts


    DEF aiDrawBitmap2
    SUBROUTINE

        REF AiStateMachine
        VEND aiDrawBitmap2

                    dec drawCount
                    bmi .next

                    lda drawCount
                    ora #SLOT2
                    sta SET_BANK_RAM
                    

                    ldx #ROW_BITMAP_SIZE/2-1

.draw               lda SampleBitmap2,x
                    ora@RAM ChessBitmap,x
                    sta@RAM ChessBitmap,x

                    lda SampleBitmap2+ROW_BITMAP_SIZE/2,x
                    ora@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x
                    sta@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x

                    dex
                    bpl .draw
                    rts

.next                PHASE WaitBitmap
                    rts

    DEF aiDrawBitmap3
    SUBROUTINE

        REF AiStateMachine
        VEND aiDrawBitmap3


                    lda #SLOT2|4
                    sta SET_BANK_RAM
                    

                    ldx #ROW_BITMAP_SIZE/2-1

.draw               lda SampleBitmap3,x
                    ora@RAM ChessBitmap,x
                    sta@RAM ChessBitmap,x

                    lda SampleBitmap3+ROW_BITMAP_SIZE/2,x
                    ora@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x
                    sta@RAM ChessBitmap+ROW_BITMAP_SIZE/2,x

;                    lda SampleBitmap,y
;                    ora@RAM ChessBitmap+6,x
;                    sta@RAM ChessBitmap+6,x
                    
;                    lda SampleBitmap,y
;                    ora@RAM ChessBitmap+12,x
;                    sta@RAM ChessBitmap+12,x

;                    iny

                    dex
                    bpl .draw



                    PHASE WaitBitmap
                ;PHASE DrawBitmap
                    rts


    DEF Phaser
    .byte 0, 1, 2, 3


    DEF SampleBitmap


    ; line 7,6,5,4,3,2,1,0
    ; R/G/B on successive lines
    ; PF0/PF1/PF2/PF0/PF1/PF2
    ; x axis goes downwards

    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%00000000,%00000000,%00000000,%00000000
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
    



    DEF SampleBitmap2
    DEF SampleBitmap3

    ; line 7,6,5,4,3,2,1,0
    ; R/G/B on successive lines
    ; PF0/PF1/PF2/PF0/PF1/PF2
    ; x axis goes downwards

    ;     7         6         5         4         3         2         1         0
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;R PF0 left
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;B

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;PF1
    .byte %01100100,%10010100,%10000100,%10000100,%10000111,%10000100,%10010100,%01100100 ;B
    .byte %01100100,%10010100,%10000100,%10000100,%10000111,%10000100,%10010100,%01100100 ;B

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;PF1
    .byte %00111101,%10000101,%10000101,%10000101,%10011101,%10000101,%10000101,%00111101
    .byte %00111101,%10000101,%10000101,%10000101,%10011101,%10000101,%10000101,%00111101

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;PF1
    .byte %00110000,%00000001,%10000001,%00000001,%00000001,%00000001,%00001111,%00110000
    .byte %00110000,%00000001,%10000001,%00000001,%00000001,%00000001,%00001111,%00110000

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;PF1
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %10000001,%00000000,%10000001,%00000001,%00000001,%00000001,%00000001,%00000001
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G



    ; line 7,6,5,4,3,2,1,0
    ; R/G/B on successive lines
    ; PF0/PF1/PF2/PF0/PF1/PF2
    ; x axis goes downwards

    ;     7         6         5         4         3         2         1         0
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;R PF0 left
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;B

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %01100100,%10010100,%10000100,%10000100,%10000111,%10000100,%10010100,%01100100 ;B

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00111101,%10000101,%10000101,%10000101,%10011101,%10000101,%10000101,%00111101

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00110000,%00000001,%10000001,%00000001,%00000001,%00000001,%00001111,%00110000

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;PF1
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000 ;G
    .byte %10000001,%00000000,%10000001,%00000001,%00000001,%00000001,%00000001,%00000001



;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
;EOF