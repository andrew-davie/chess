; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


RESERVED_FOR_STACK  = 12                            ; bytes guaranteed not overwritten by variable use
TOP_OF_STACK        = $FF-RESERVED_FOR_STACK

    ds RESERVED_FOR_STACK

; WARNING/NOTE - the alphabeta search violates the above size constraints
; HOWEVER, the "OVERLAY" segment is beneath this, and will be stomped, depending on # plys
;  but since overlay is not generally stressed during alphabeta, we're good.

; Ensure there isn't any stomping of stack/overlay excess usage

    ECHO "Overlay boundary: ", Overlay + MAXIMUM_REQUIRED_OVERLAY_SIZE
    ECHO "Stack boundary: ", $FF- PLY_BANKS*2

    IF ($FF - PLY_BANKS*2) < (Overlay + MAXIMUM_REQUIRED_OVERLAY_SIZE)
        ECHO "ERROR: Not enough reserved space for stack with given #PLY"
        ERR
    ENDIF

    ;IF TOP_OF_STACK <= (Overlay + MAXIMUM_REQUIRED_OVERLAY_SIZE)
    ;    ECHO "ERROR: Not enough reserved space for stack"
    ;    ERR
    ;ENDIF


