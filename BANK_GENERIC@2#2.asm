
            SLOT 2
            ROMBANK GENERIC_BANK@2#2


;---------------------------------------------------------------------------------------------------


    DEF moveCursor
    SUBROUTINE

        REFER aiSelectStartSquare
        REFER aiSelectDestinationSquare

        VAR __newCursor, 1
        
        VEND moveCursor

    ; Part (a) move cursor around the board waiting for joystick press

                    ldx #0                  ; delay

                    lda SWCHA
                    lsr
                    lsr
                    lsr
                    lsr
                    tay

                    cmp #15
                    beq .cursor             ; nothing pressed - skip delays

                    dec mdelay
                    bpl .delaym

                    clc
                    lda cursorX12
                    adc JoyMoveCursor,y
                    sta __newCursor
                    tay

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda ValidSquare,y
                    cmp #-1
                    beq .invalid
                    lda __newCursor
                    sta cursorX12
.invalid

                    ldx #CURSOR_MOVE_SPEED
.cursor             stx mdelay
                    jsr setCursorPriority
.delaym             rts


;---------------------------------------------------------------------------------------------------

    DEF setCursorPriority
    SUBROUTINE

        REFER moveCursor
        VEND setCursorPriority

                    tya
                    pha

                    ldx #%100

                    ldy cursorX12
                    bmi .under

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    bne .under
                    ldx #0
.under              stx CTRLPF                  ; UNDER

                    pla
                    tay
                    rts


;---------------------------------------------------------------------------------------------------

    DEF setCursorColours
    SUBROUTINE

        REFER aiSelectStartSquare
        REFER aiDrawMoves
        REFER aiUnDrawTargetSquares
        REFER aiShowMoveCaptures
        REFER aiSlowFlash
        REFER aiSelectDestinationSquare
        VEND setCursorColours

    ; pass y=-1 if move is NOT in the movelist
    ; preserve y

                    lda #$42

                    cpy #-1
                    beq .writeCursorCol             ; NOT in the movelist

                    lda ccur
                    lsr
                    lsr
                    lsr
                    and #6
                    clc
                    adc #$D2 ;COLOUR_LINE_1

.writeCursorCol     sta COLUP0
                    rts


;---------------------------------------------------------------------------------------------------

;          RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
;          0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111

    ALLOCATE JoyCombined, 16
    .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   1,  -1,   0

    ALLOCATE JoyMoveCursor, 16
    .byte     0,   0,   0,   0,   0,  -9,  11,   1,   0, -11,  9,  -1,   0,  -10,  10,   0


;---------------------------------------------------------------------------------------------------

            CHECK_BANK_SIZE "BANK_GENERIC@2#2"

;---------------------------------------------------------------------------------------------------
;EOF
