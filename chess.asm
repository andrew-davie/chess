; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


TIA_BASE_ADDRESS = 0 ;$40

    processor 6502
    include "vcs.h"
    include "macro.h"
    include "_ MACROS.asm"
    include "piece_defines.h"

VERBOSE                 = 0                         ; set to 1 for compile messages

ORIGIN          SET 0
ORIGIN_RAM      SET 0

                ;include "segtime.asm"


_FIRST_BANK          = 0                             ; 3E+ 1st bank holds reset vectors

;FIXED_BANK             = 3 * 2048           ;-->  8K ROM tested OK
;FIXED_BANK              = 7 * 2048          ;-->  16K ROM tested OK
;FIXED_BANK             = 15 * 2048           ; ->> 32K
;FIXED_BANK             = 31 * 2048           ; ->> 64K
;FIXED_BANK             = 239 * 2048         ;--> 480K ROM tested OK (KK/CC2 compatibility)
;FIXED_BANK             = 127 * 2048         ;--> 256K ROM tested OK
;FIXED_BANK             = 255 * 2048         ;--> 512K ROM tested OK (CC2 can't handle this)

YES                     = 1
NO                      = 0
HUMAN                   = 64

INFINITY                = $7000-1 ;32767


; assemble diagnostics. Remove for release.

TEST_POSITION           = 0                         ; 0=normal, 1 = setup test position
DIAGNOSTICS             = 0
QUIESCENCE              = 1
ASSERTS                 = 0
PVSP                    = 0                         ; player versus player =1
ENPASSANT_ENABLED       = 1
CASTLING_ENABLED        = 1
;RAINBOW                 = 1                        ; comment out to disable

SELECT_SWITCH           = 2                         ; (SWCHB & SELECT_SWITCH)  0 == PRESSED


; NOTE: SEARCH_DEPTH cannot be < 3, because the player's moves are generated from PLY+1, and use
; PLY+2 for computer response (thus, 3). The bank allocation gets stomped!


SEARCH_DEPTH            = 4
QUIESCE_EXTRA_DEPTH     = 4


    IF SEARCH_DEPTH < 3
        ECHO "ERROR: Search depth must be >= 3"
        ERR
    ENDIF



PLY_BANKS = SEARCH_DEPTH + QUIESCE_EXTRA_DEPTH
MAX_PLY_DEPTH_BANK = PLY_BANKS   ;TODO -- RAMBANK_PLY + PLY_BANKS

    ;IF RAMBANK_PLY + MAX_PLY_DEPTH_BANK > 31
    ;    ERR "Not enough RAM for PLY banks"
    ;ENDIF




SWAP_SIDE               = 128 ;TODO + (RAMBANK_PLY ^ (RAMBANK_PLY+1))



; DELAYS

READY_TO_MOVE_FLASH             = 10

;===================================
FINAL_VERSION                  = NO           ; this OVERRIDES any selections below and sets everything correct for a final release
;===================================

;-------------------------------------------------------------------------------
; The following are optional YES/NO depending on phase of the moon
L276                            SET YES         ; use 276 line display for NTSC
;-------------------------------------------------------------------------------
; DO NOT MODIFY THE BELOW SETTINGS -- USE THE ONES ABOVE!
; Here we make sure everyting is OK based on the single switch -- less chance for accidents
 IF FINAL_VERSION = YES
L276                            SET YES         ; use 276 line display for NTSC
 ENDIF

;-------------------------------------------------------------------------------

COMPILE_ILLEGALOPCODES          = 1

DIRECTION_BITS              = %111              ; for ManLastDirection

;------------------------------------------------------------------------------

PLUSCART = NO

;------------------------------------------------------------------------------


CHESSBOARD_ROWS            = 8                 ; number of ROWS of chessboard
LINES_PER_CHAR              = 24                ; MULTIPLE OF 3 SO RGB INTERFACES CHARS OK
PIECE_SHAPE_SIZE            = 72                ; 3 PF bytes x 24 scanlines

SET_BANK                    = $3F               ; write address to switch ROM banks
SET_BANK_RAM                = $3E               ; write address to switch RAM banks


RAM_SIZE                    = $400              ; address space for write AND read
RAM_WRITE                   = $200              ; add this to RAM address when doing writes
RAM                         = RAM_WRITE

_ROM_BANK_SIZE               = $400
_RAM_BANK_SIZE               = $200


; Platform constants:
PAL                 = %10
PAL_50              = PAL|0
PAL_60              = PAL|1

NTSC_COLOUR_LINE_1 = $84        ; blue
NTSC_COLOUR_LINE_2 = $46        ; red
NTSC_COLOUR_LINE_3 = $D8        ; green

PAL_COLOUR_LINE_1 = $D4         ; blue
PAL_COLOUR_LINE_2 = $68         ; red
PAL_COLOUR_LINE_3 = $3A         ; green


TIME_PART_2         = 46 ;68
TIME_PART_1         = 45 ;66
TIME_PART_2_PAL         = 56
TIME_PART_1_PAL         = 78


SLOT0               = 0
SLOT1               = 64
SLOT2               = 128
SLOT3               = 192


;---------------------------------------------------------------------------------------------------

    #include "zeropage.asm"
    #include "overlays.asm"
    #include "stack.asm"

    ECHO "FREE BYTES IN ZERO PAGE = ", $FF - *
    IF * > $FF
        ERR "Zero Page overflow!"
    ENDIF

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

    ; NOW THE VERY INTERESTING '3E' RAM BANKS
    ; EACH BANK HAS A READ-ADDRESS AND A WRITE-ADDRESS, WITH 512 bytes TOTAL ACCESSIBLE
    ; IN A 1K MEMORY SPACE


;---------------------------------------------------------------------------------------------------


    MAC PHASE ;#
        lda #AI_{1}
        sta aiState
    ENDM


;--------------------------------------------------------------------------------

    include "_ PIECE MACROS.asm"

    include "@3 STARTBANK.asm"                       ; MUST be first ROM bank

    include "@0 HOME.asm"

    include "@1 GENERIC #1.asm"
    include "@1 NEGAMAX.asm"
    include "@1 STATE MACHINE #1.asm"
    include "@1 STATE MACHINE #2.asm"
    include "@1 PIECE HANDLER #1.asm"
    include "@1 PIECE HANDLER #2.asm"

    include "@2 SCREEN RAM.asm"
    include "@2 PLY.asm"
    include "@2 PLY2.asm"
    include "@2 GENERIC #3.asm"
    include "@2 GENERIC #4.asm"
    include "@2 GRAPHICS DATA.asm"
    include "@2 VOX.asm"

    include "@3 GENERIC #2.asm"
    include "@3 SCREEN ROM.asm"
    include "@3 EVALUATE.asm"
    include "@2 WORDS.asm"

    include "SHADOW_BOARD.asm"



    include "TitleScreen.asm"
    include "TitleScreen@2.asm"



    ALIGN _ROM_BANK_SIZE

    ECHO [_ORIGIN/_ROM_BANK_SIZE]d, "ROM BANKS"
    ECHO [ORIGIN_RAM / _RAM_BANK_SIZE]d, "RAM BANKS"

;---------------------------------------------------------------------------------------------------
;EOF
