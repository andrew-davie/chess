; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

            NEWBANK INITBANK


;                      RLDU RLD  RL U RL   R DU R D  R  U R     LDU  LD   L U  L     DU   D     U
;                      0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111
JoyMoveX        .byte     0,   0,   0,   0,   0,   1,   1,   1,   0,  -1,  -1,  -1,   0,   0,   0,   0
JoyMoveY        .byte     0,   0,   0,   0,   0,   1,  -1,   0,   0,   1,  -1,   0,   0,   1,  -1,   0

JoyDirY
    .byte   0,0;,1,-1,0
JoyDirX
    .byte   1,-1,0,0,0

;Data Bit  Direction Player
;               D7        right          P0  D4
;               D6        left      P0  D3
;               D5        down      P0  D2
;               D4        up        P0  D1
;     A "0" in a data bit indicates the joystick has been moved
;     to close that switch.  All "1's" in a player's nibble
;     indicates that joystick is not moving.

;0  0000 x
;1  0001 x
;2  0010 x
;3  0011 x
;4  0100 x
;5  0101 right down
;6  0110 right up
;7  0111 right
;8  1000 x
;9  1001 left down
;10  1010 left up
;11  1011 left
;12  1100 x
;13  1101 down
;14  1110 up
;15  1111 none


    ;------------------------------------------------------------------------------

;------------------------------------------------------------------------------


    CHECK_BANK_SIZE "INITBANK"
