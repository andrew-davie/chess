; Copyright (C)2020 Andrew Davie
; Common macros for piece move handlers

;---------------------------------------------------------------------------------------------------
; Looks at a square offset {1} to see if piece can move to it
; Adds the square to the movelist if it can
; Keeps moving in the same direction until it's blocked/off=board

    MAC MOVE_TOWARDS
    SUBROUTINE

                ldx currentSquare
                bpl .project                    ; unconditional

.empty          jsr AddMove
.project        ldy ValidSquare+{1},x
                bmi .invalid                    ; off board!
                lda Board,y                     ; piece @ destination
                beq .empty
                eor currentPiece
                bpl .invalid                    ; same colour
                jsr AddMove                     ; and exit

.invalid
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC MOVE_TO
    SUBROUTINE
                ldy ValidSquare+{1},x
                bmi .invalid                    ; off board!
                lda Board,y                     ; piece @ destination
                beq .squareEmpty

                eor currentPiece
                bpl .invalid                    ; same colour

.squareEmpty    jsr AddMove
                ldx currentSquare

.invalid
    ENDM

;---------------------------------------------------------------------------------------------------
; EOF
