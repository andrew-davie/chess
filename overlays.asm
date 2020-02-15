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

    MAC OVERLAY ; {name}
OVERLAY_NAME SET {1}
    SEG.U OVERLAY_{1}
        org Overlay
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC VALIDATE_OVERLAY
        LIST OFF
OVERLAY_DELTA SET * - Overlay
        IF OVERLAY_DELTA > MAXIMUM_REQUIRED_OVERLAY_SIZE
MAXIMUM_REQUIRED_OVERLAY_SIZE SET OVERLAY_DELTA
        ENDIF
        IF OVERLAY_DELTA > OVERLAY_SIZE
            ECHO "Overlay", OVERLAY_NAME, "is too big!"
            ECHO "REQUIRED SIZE =", OVERLAY_DELTA
            ERR
        ENDIF
        LIST ON
        ECHO OVERLAY_NAME, "-", OVERLAY_SIZE - ( * - Overlay ), "bytes available"
    ENDM

;---------------------------------------------------------------------------------------------------

OVERLAY_SIZE    SET $4C           ; maximum size
MAXIMUM_REQUIRED_OVERLAY_SIZE       SET 0


; This overlay variable is used for the overlay variables.  That's OK.
; However, it is positioned at the END of the variables so, if on the off chance we're overlapping
; stack space and variable, it is LIKELY that that won't be a problem, as the temp variables
; (especially the latter ones) are only used in rare occasions.

; FOR SAFETY, DO NOT USE THIS AREA DIRECTLY (ie: NEVER reference 'Overlay' in the code)
; ADD AN OVERLAY FOR EACH ROUTINE'S USE, SO CLASHES CAN BE EASILY CHECKED

Overlay         ds OVERLAY_SIZE       ;--> overlay (share) variables
END_OF_OVERLAY

;---------------------------------------------------------------------------------------------------
; And now... the overlays....

    ECHO "---- OVERLAYS (", OVERLAY_SIZE, "bytes ) ----"

;---------------------------------------------------------------------------------------------------

    OVERLAY "PieceBufferOverlay"
; used in CopyPieceFromRAMBufferToScreen
; used in CopyPieceToRAMBuffer
; used in ClearChessBitmap
; used in CopyPieceToRowBitmap
__pieceShapeBuffer      ds PIECE_SHAPE_SIZE
__ptr                   ds 2                ; pointer to data
__ptr2                  ds 2                ; pointer to data
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------

    OVERLAY "CopyROMShadowToRAM"
__CopyCount             ds 1
__ROM_SourceBank        ds 1
__index                 ds 1
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------

    OVERLAY "DrawTheChessScreen"
__rows                  ds 1
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------

    OVERLAY "SetupShadowRAM"
__destinationBank       ds 1
__sourceBank            ds 1
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "DrawPiece"
__pieceColour           ds 1
__boardc                ds 1

    VALIDATE_OVERLAY


;---------------------------------------------------------------------------------------------------
    OVERLAY "InitPly"
__plyBank               ds 1
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "RandomPiece"
__tempx           ds 1
    VALIDATE_OVERLAY

    OVERLAY "Overlay000"
__fromRow                       ds 1
    VALIDATE_OVERLAY
;---------------------------------------------------------------------------------------------------
    OVERLAY "Overlay001"
__from                       ds 1
__to                         ds 1
    VALIDATE_OVERLAY
;---------------------------------------------------------------------------------------------------

    OVERLAY "Handlers"
__piece                 ds 1
__vector                ds 2
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "Movers"
__fromCol               ds 1
__toCol                 ds 1
__temp                  ds 1

    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "checkPieces"
__x                     ds 1
__bank                  ds 1

    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "aiSelectStartSquare"
__cursorColour          ds 1
    VALIDATE_OVERLAY

;---------------------------------------------------------------------------------------------------
    OVERLAY "TitleScreen"
__colour_table          ds 2
    VALIDATE_OVERLAY
;---------------------------------------------------------------------------------------------------

    OVERLAY "SAFE_showMoveOptions"
__moveDotColour          ds 2
    VALIDATE_OVERLAY
;---------------------------------------------------------------------------------------------------

    ORG END_OF_OVERLAY
    ECHO "---- END OF OVERLAYS ----"
    ECHO "MAXIMUM OVERLAY SIZE NEEDED = ", MAXIMUM_REQUIRED_OVERLAY_SIZE

;EOF
