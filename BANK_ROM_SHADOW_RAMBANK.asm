; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------
                NEWBANK ROM_SHADOW_OF_RAMBANK_CODE
    ;------------------------------------------------------------------------------

;*** Ideas: ***
; - separate data for left and right nibble (saves 88 cycles, 63 cycles or
;   13.5% on average), also unrolling would be more effective than now
; - use CharacterDataVecHI for mirrored/unmirrored (saves cycles and bytes,
;   see EXPERIMENTAL)
; - special QuickDraw routine for PF0 (~165 cycles, but only ~2% usage)
; - stack AI (reordering for less setup code and cycle usage, maybe better use
;   bidirectional linked list instead)
; - calculate mirrored gfx data into RAM (saves ROM)

;*** average cycle calculation (10% blanks, all columns equally frequent): ***
;currently:
; 72%*539 (!unrolled)
;+ 8%*304 (unrolled)
;+20%*269 (unrolled)
;--------
;=   ~466.2 cycles on average

;alternative #1:
; 72%*522 (unrolled)
;+ 8%*352 (!unrolled)
;+20%*307 (!unrolled)
;--------
;=   ~465.4 cycles on average


    ; WARNING: DO NOT ALLOW A rts AS LAST BYTE OF BANK, as it triggers a write at F400 access

    CHECK_HALF_BANK_SIZE "ROM_SHADOW_OF_RAMBANK_CODE -- 1K"

    ; Here there's another 1K of usable ROM....
    ; Anything here is ONLY accessible if the bank is switched in as a ROM bank
    ; WE CAN'T HAVE ANYTHING REQUIRED IN THE ROM_SHADOW (IN RAM) IN THIS HALF

    CHECK_BANK_SIZE "ROM_SHADOW_OF_RAMBANK_CODE -- full 2K"
