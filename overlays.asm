; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------
; OVERLAYS!
; These variables are overlays, and should be managed with care
; They co-exist (each "OVERLAY" starts at the zero-page variable "Overlay"
; and thus, overlays cannot be used at the same time (that is, you cannot
; use a variable in overlay #1 while at the same time using a variable in
; overlay #2

; for clarity, prefix ALL overlay variables with double-underscore (__)

; TOTAL SPACE USED BY ANY OVERLAY GROUP SHOULD BE <= SIZE OF 'Overlay'
; ensure this by using the VALIDATE_OVERLAY macro
;---------------------------------------------------------------------------------------------------


;OVERLAY_SIZE    SET $4C           ; maximum size
MAXIMUM_REQUIRED_OVERLAY_SIZE       SET 0


; This overlay variable is used for the overlay variables.  That's OK.
; However, it is positioned at the END of the variables so, if on the off chance we're overlapping
; stack space and variable, it is LIKELY that that won't be a problem, as the temp variables
; (especially the latter ones) are only used in rare occasions.

; FOR SAFETY, DO NOT USE THIS AREA DIRECTLY (ie: NEVER reference 'Overlay' in the code)
; ADD AN OVERLAY FOR EACH ROUTINE'S USE, SO CLASHES CAN BE EASILY CHECKED

    DEF Overlay
    ds MAXIMUM_REQUIRED_OVERLAY_SIZE       ;--> overlay (share) variables
END_OF_OVERLAY

;---------------------------------------------------------------------------------------------------
; And now... the overlays....

    ;ECHO "---- OVERLAYS (", OVERLAY_SIZE, "bytes ) ----"

;---------------------------------------------------------------------------------------------------

    DEF Variable_PieceShapeBuffer
    VAR __pieceShapeBuffer, PIECE_SHAPE_SIZE
    VEND Variable_PieceShapeBuffer

;---------------------------------------------------------------------------------------------------


    ORG END_OF_OVERLAY
    ECHO "---- END OF OVERLAYS ----"
    ECHO "MAXIMUM OVERLAY SIZE NEEDED = ", MAXIMUM_REQUIRED_OVERLAY_SIZE

;EOF
