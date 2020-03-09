; Copyright (C)2020 Andrew Davie
; Common macros for piece move handlers

;---------------------------------------------------------------------------------------------------
; Looks at a square offset {1} to see if piece can move to it
; Adds the square to the movelist if it can
; Keeps moving in the same direction until it's blocked/off=board

    MAC MOVE_TOWARDS
    SUBROUTINE

    ; = 76 for single square (empty/take)

                ldx currentSquare               ; 3
                bne .project                    ; 3   unconditional

.empty          jsr AddMove                     ; 57
.project        ldy ValidSquare+{1},x           ; 4
                bmi .invalid                    ; 2/3 off board!
                lda Board,y                     ; 4   piece @ destination
                beq .empty                      ; 2/3
                eor currentPiece                ; 3
                bpl .invalid                    ; 2/3 same colour
                jsr AddMove                     ; 57  and exit

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
.invalid
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC MOVE_TO_X
                ldx currentSquare
                MOVE_TO {1}
    ENDM


;---------------------------------------------------------------------------------------------------
; EOF
