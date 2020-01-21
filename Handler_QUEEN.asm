; Copyright (C)2020 Andrew Davie

; This is the move handler for a QUEEN

    NEWRAMBANK HANDLER_MOVE

    include "common_vectors.asm"         ; MUST BE FIRST

;---------------------------------------------------------------------------------------------------
; MACRO - Common code
; Looks at a square offset {1} to see if piece can move to it
; Adds the square to the movelist if it can
; Keeps moving in the same direction until it's blocked/off=board

    MAC MOVE_TOWARDS
    SUBROUTINE

                ldx currentSquare
.project        ldy ValidSquare+{1},x
                bmi .invalid                    ; off board!
                lda Board,y                     ; piece @ destination
                beq .squareEmpty

                eor currentPiece
                bpl .invalid                    ; same colour

.squareEmpty    jsr AddMove

                lda Board,y
                bne .invalid                    ; stop when we hit something

                tya
                tax                             ; move to next square
                jmp .project

.invalid
    ENDM

    MAC MOVE_TO
    SUBROUTINE

                ldy ValidSquare+{1},x
                bmi .invalidK                   ; off board!
                lda Board,y                     ; piece @ destination
                beq .squareEmpty

                eor currentPiece
                bpl .invalidK                   ; same colour

.squareEmpty    jsr AddMove
.invalidK
    ENDM


;---------------------------------------------------------------------------------------------------
; QUEEN
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_QUEEN

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN+_LEFT
                MOVE_TOWARDS _DOWN
                MOVE_TOWARDS _DOWN+_RIGHT
                MOVE_TOWARDS _RIGHT
                MOVE_TOWARDS _UP+_RIGHT
                MOVE_TOWARDS _UP
                MOVE_TOWARDS _UP+_LEFT
                MOVE_TOWARDS _LEFT
                rts

;---------------------------------------------------------------------------------------------------
; ROOK
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_ROOK

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN
                MOVE_TOWARDS _RIGHT
                MOVE_TOWARDS _UP
                MOVE_TOWARDS _LEFT
                rts

;---------------------------------------------------------------------------------------------------
; BISHOP
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_BISHOP

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TOWARDS _DOWN+_LEFT
                MOVE_TOWARDS _DOWN+_RIGHT
                MOVE_TOWARDS _UP+_LEFT
                MOVE_TOWARDS _UP+_RIGHT
                rts

;---------------------------------------------------------------------------------------------------
; KNIGHT
;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Handle_KNIGHT

    ; Pass...
    ; x = currentSquare (square the piece is on)
    ; currentPiece (with flags/colour attached)

                MOVE_TO _DOWN+_DOWN+_LEFT
                MOVE_TO _DOWN+_DOWN+_RIGHT
                MOVE_TO _UP+_UP+_LEFT
                MOVE_TO _UP+_UP+_RIGHT

                MOVE_TO _DOWN+_LEFT+_LEFT
                MOVE_TO _DOWN+_RIGHT+_RIGHT
                MOVE_TO _UP+_LEFT+_LEFT
                MOVE_TO _UP+_RIGHT+_RIGHT

                rts


            CHECK_HALF_BANK_SIZE "HANDLER_MOVE -- 1K"
