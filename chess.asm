; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


TIA_BASE_ADDRESS = $40

                processor 6502
                include "vcs.h"
                include "macro.h"
                include "piece_defines.h"

VERBOSE                 = 0                         ; set to 1 for compile messages

ORIGIN          SET 0
ORIGIN_RAM      SET 0

                include "segtime.asm"


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

INFINITY                = $7000 ;32767


; assemble diagnostics. Remove for release.

TEST_POSITION           = 0                         ; 0=normal, 1 = setup test position
DIAGNOSTICS             = 1
QUIESCENCE              = 1
ASSERTS                 = 0
PVSP                    = 0                         ; player versus player =1
ENPASSANT_ENABLED       = 0
CASTLING_ENABLED        = 1

; NOTE: SEARCH_DEPTH cannot be < 3, because the player's moves are generated from PLY+1, and use
; PLY+2 for computer response (thus, 3). The bank allocation gets stomped!


SEARCH_DEPTH            = 4
QUIESCE_EXTRA_DEPTH     = 0


    IF SEARCH_DEPTH < 3
    ECHO "ERROR: Search depth nust be >= 3"
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

PLUSCART = YES

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


    IF L276
VBLANK_TIM_NTSC     = 48                        ; NTSC 276 (Desert Falcon does 280, so this should be pretty safe)
    ELSE
VBLANK_TIM_NTSC     = 50                        ; NTSC 262
    ENDIF
VBLANK_TIM_PAL      = 85 ;85                        ; PAL 312 (we could increase this too, if we want to, but I suppose the used vertical screen size would become very small then)

    IF L276
OVERSCAN_TIM_NTSC   = 35 ;24 ;51                        ; NTSC 276 (Desert Falcon does 280, so this should be pretty safe)
    ELSE
OVERSCAN_TIM_NTSC   = 8 ;51                        ; NTSC 262
    ENDIF
OVERSCAN_TIM_PAL    = 41                        ; PAL 312 (we could increase this too, if we want to, but I suppose the used vertical screen size would become very small then)

    IF L276
SCANLINES_NTSC      = 276                       ; NTSC 276 (Desert Falcon does 280, so this should be pretty safe)
    ELSE
SCANLINES_NTSC      = 262                       ; NTSC 262
    ENDIF
SCANLINES_PAL       = 312


TIME_PART_2         = 46
TIME_PART_1         = 46


SLOT0               = 0
SLOT1               = 64
SLOT2               = 128
SLOT3               = 192

;------------------------------------------------------------------------------
; MACRO definitions



            MAC NEWBANK ; bank name
                SEG {1}
                ORG _ORIGIN
                RORG _BANK_ADDRESS_ORIGIN
_BANK_START     SET *
{1}_START       SET *
_CURRENT_BANK   SET _ORIGIN/1024
{1}             SET _BANK_SLOT + _CURRENT_BANK
_ORIGIN         SET _ORIGIN + 1024
            ENDM

;            MAC DEFINE_1K_SEGMENT ; {seg name}
;                ALIGN $400
;SEGMENT_{1}     SET *
;BANK_{1}        SET _CURRENT_BANK
;            ENDM

    MAC CHECK_BANK_SIZE ; name
.TEMP = * - _BANK_START
    ECHO {1}, "(1K) SIZE = ", .TEMP, ", FREE=", _ROM_BANK_SIZE - .TEMP
    IF ( .TEMP ) > _ROM_BANK_SIZE
        ECHO "BANK OVERFLOW @ ", {1}, " size=", * - ORIGIN
        ERR
    ENDIF
    ENDM

    MAC CHECK_RAM_BANK_SIZE ; name
.TEMP = * - _BANK_START
    ECHO {1}, "(512 byte) SIZE = ", .TEMP, ", FREE=", _RAM_BANK_SIZE - .TEMP
    IF ( .TEMP ) > _RAM_BANK_SIZE
        ECHO "BANK OVERFLOW @ ", {1}, " size=", * - ORIGIN
        ERR
    ENDIF
    ENDM

;---------------------------------------------------------------------------------------------------

    ; Macro inserts a page break if the object would overlap a page

    MAC OPTIONAL_PAGEBREAK ; { string, size }
        LIST OFF
        IF (>( * + {2} -1 )) > ( >* )
EARLY_LOCATION  SET *
            ALIGN 256
            IF VERBOSE=1
            ECHO "PAGE BREAK INSERTED FOR", {1}
            ECHO "REQUESTED SIZE =", {2}
            ECHO "WASTED SPACE =", *-EARLY_LOCATION
            ECHO "PAGEBREAK LOCATION =", *
            ENDIF
        ENDIF
        LIST ON
    ENDM


    MAC CHECK_PAGE_CROSSING
        LIST OFF
    IF ( >BLOCK_END != >BLOCK_START )
        ECHO "PAGE CROSSING @ ", BLOCK_START
    ENDIF
    LIST ON
    ENDM

    MAC CHECKPAGE
        LIST OFF
        IF >. != >{1}
            ECHO ""
            ECHO "ERROR: different pages! (", {1}, ",", ., ")"
            ECHO ""
        ERR
        ENDIF
        LIST ON
    ENDM

    MAC CHECKPAGEX
        LIST OFF
        IF >. != >{1}
            ECHO ""
            ECHO "ERROR: different pages! (", {1}, ",", ., ") @ {0}"
            ECHO {2}
            ECHO ""
        ERR
        ENDIF
        LIST ON
    ENDM

;---------------------------------------------------------------------------------------------------

    ; Defines a variable of the given size, making sure it doesn't cross a page
    MAC VARIABLE ; {name, size}
    OPTIONAL_PAGEBREAK "Variable", {2}
{1} ds {2}
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC DEF               ; name of subroutine
SLOT_{1}        SET _BANK_SLOT
BANK_{1}        SET SLOT_{1} + _CURRENT_BANK         ; bank in which this subroutine resides
{1}                                     ; entry point
TEMPORARY_VAR SET Overlay
TEMPORARY_OFFSET SET 0
VAR_BOUNDARY_{1} SET TEMPORARY_OFFSET
FUNCTION_NAME SET {1}
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC ALLOCATE
    OPTIONAL_PAGEBREAK "Table", {2}
    DEF {1}
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC SLOT ; {1}
    IF ({1} < 0) || ({1} > 3)
        ECHO "Illegal bank address/segment location", {1}
        ERR
    ENDIF
_BANK_ADDRESS_ORIGIN SET $F000 + ({1} * _ROM_BANK_SIZE)
_BANK_SLOT SET {1} * 64               ; D7/D6 selector
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC NEGEVAL

                    sec
                    lda #0
                    sbc Evaluation
                    sta Evaluation
                    lda #0
                    sbc Evaluation+1
                    sta Evaluation+1
    ENDM


    MAC SWAP
                    lda sideToMove
                    eor #SWAP_SIDE
                    sta sideToMove

                    ;NEGEVAL
    ENDM


;---------------------------------------------------------------------------------------------------

TEMPORARY_OFFSET SET 0


    MAC VEND ; {1}
    IFNCONST {1}
        ECHO "Incorrect VEND label", {1}
        ERR
    ENDIF
VAREND_{1} = TEMPORARY_VAR
    ENDM


    MAC REFER ; {1}
        IF VAREND_{1} > TEMPORARY_VAR
TEMPORARY_VAR SET VAREND_{1}
        ENDIF
    ENDM



    ; Define a temporary variable for use in a subroutine
    ; Will allocate appropriate bytes, and also check for overflow of the available overlay buffer

    MAC VAR ; { name, size }
{1} = TEMPORARY_VAR
TEMPORARY_VAR SET TEMPORARY_VAR + TEMPORARY_OFFSET + {2}

OVERLAY_DELTA SET TEMPORARY_VAR - Overlay
        IF OVERLAY_DELTA > MAXIMUM_REQUIRED_OVERLAY_SIZE
MAXIMUM_REQUIRED_OVERLAY_SIZE SET OVERLAY_DELTA
        ENDIF
        IF OVERLAY_DELTA > OVERLAY_SIZE
            ECHO "Temporary Variable", {1}, "overflow!"
            ERR
        ENDIF
        LIST ON
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC TAG ; {ident/tag}
; {0}
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC sta@RAM ;{}
        sta [RAM]+{0}
    ENDM

    MAC stx@RAM
        stx [RAM]+{0}
    ENDM

    MAC sty@RAM
        sty [RAM]+{0}
    ENDM

    MAC sta@PLY ;{}
        sta [RAM]+{0}
    ENDM

    MAC stx@PLY
        stx [RAM]+{0}
    ENDM

    MAC sty@PLY
        sty [RAM]+{0}
    ENDM


    MAC lda@RAM ;{}
        lda {0}
    ENDM

    MAC ldx@RAM ;{}
        ldx {0}
    ENDM

    MAC ldy@RAM ;{}
        ldy {0}
    ENDM


    MAC lda@PLY ;{}
        lda {0}
    ENDM

    MAC ldx@PLY ;{}
        ldx {0}
    ENDM

    MAC ldy@PLY ;{}
        ldy {0}
    ENDM


    MAC adc@PLY ;{}
        adc {0}
    ENDM

    MAC sbc@PLY ;{}
        sbc {0}
    ENDM

    MAC cmp@PLY ;{}
        cmp {0}
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC NEWRAMBANK ; bank name
    ; {1}       bank name
    ; {2}       RAM bank number

                SEG.U {1}
                ORG ORIGIN_RAM
                RORG _BANK_ADDRESS_ORIGIN
_BANK_START     SET *
RAMBANK_{1}     SET _BANK_SLOT + (ORIGIN_RAM / RAM_SIZE)
_CURRENT_RAMBANK SET RAMBANK_{1}
ORIGIN_RAM      SET ORIGIN_RAM + RAM_SIZE
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC RESYNC
; resync screen, X and Y == 0 afterwards
                lda #%10                        ; make sure VBLANK is ON
                sta VBLANK

                ldx #8                          ; 5 or more RESYNC_FRAMES
.loopResync
                VERTICAL_SYNC

                ldy #SCANLINES_NTSC/2 - 2
                lda Platform
                eor #PAL_50                     ; PAL-50?
                bne .ntsc
                ldy #SCANLINES_PAL/2 - 2
.ntsc
.loopWait
                sta WSYNC
                sta WSYNC
                dey
                bne .loopWait
                dex
                bne .loopResync
    ENDM

    MAC SET_PLATFORM
; 00 = NTSC
; 01 = NTSC
; 10 = PAL-50
; 11 = PAL-60
                lda SWCHB
                rol
                rol
                rol
                and #%11
                eor #PAL
                sta Platform                    ; P1 difficulty --> TV system (0=NTSC, 1=PAL)
    ENDM


;---------------------------------------------------------------------------------------------------

;    MAC JSROM_SAFE ; {routine}
;    ; Saves bank of routine to variable for later restore.
;    ; Switches to the bank and does a JSR to the routine.

;                lda #BANK_{1}
;                sta savedBank
;                sta SET_BANK
;                jsr {1}
;    ENDM


;    MAC JSROM ; {routine}

;                lda #BANK_{1}
;                sta SET_BANK
;                jsr {1}
;    ENDM


;    MAC JSRAM
;                lda #BANK_{1}
;                sta SET_BANK_RAM
;                jsr {1}
;    ENDM



    MAC TIMECHECK ; {ident}, {branch if out of time}
                    lda INTIM
                    cmp #SPEEDOF_{1}
                    bcc {2}
    ENDM


    MAC TIMING ; {label}, {cycles}
SPEEDOF_{1} = ({2}/64) + 1
    ENDM


;---------------------------------------------------------------------------------------------------

    ; Failsafe call of function in another bank
    ; This will check the slot #s for current, call to make sure they're not the same!

    MAC CALL ; function name
    IF SLOT_{1} == _BANK_SLOT
        ECHO "ERROR: Incompatible call to function requiring same slot..."
        ECHO "Cannot switch bank in use for", {0}
        ERR
    ENDIF
    lda #BANK_{1}
    sta SET_BANK
    jsr {1}
    ENDM



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

    SLOT 0
    NEWRAMBANK CHESS_BOARD_ROW
    REPEAT (CHESSBOARD_ROWS) - 1
        NEWRAMBANK .DUMMY
    REPEND

    ; NOTE: THIS BANK JUST *LOOKS* EMPTY.
    ; It actually contains everything copied from the ROM copy of the ROW RAM banks.
    ; The variable definitions are also in that ROM bank (even though they're RAM :)

    ; Now we have the actual graphics data for each of the rows.  This consists of an
    ; actual bitmap (in exact PF-style format, 6 bytes per line) into which the
    ; character shapes are masked/copied. The depth of the character shapes may be
    ; changed by changing the #LINES_PER_CHAR value.  Note that this depth should be
    ; a multiple of 3, so that the RGB scanlines match at character joins.

    ; We have one bank for each chessboard row.  These banks are duplicates of the above,
    ; accessed via the above labels but with the appropriate bank switched in.

;---------------------------------------------------------------------------------------------------


RND_EOR_VAL = $FE ;B4

    MAC	NEXT_RANDOM
        lda	rnd
        lsr
        bcc .skipEOR
        eor #RND_EOR_VAL
.skipEOR    sta rnd
    ENDM

;--------------------------------------------------------------------------------

    MAC PHASE ;#
        lda #{1}
        sta aiState
    ENDM


;--------------------------------------------------------------------------------

    MAC COMMON_VARS_ALPHABETA

        VAR __thinkbar, 1
        VAR __toggle, 1

        VAR __bestMove, 1
        VAR __alpha, 2
        VAR __beta, 2
        VAR __negaMax, 2
        VAR __value, 2

        VAR __quiesceCapOnly, 1

    ENDM


;---------------------------------------------------------------------------------------------------

    include "BANK_FIRST@0.asm"                        ; MUST be first in ROM - contains reset vectors
    include "BANK_GENERIC@1#1.asm"
    include "BANK_ROM_SHADOW_SCREEN.asm"
    include "ROM_SCREEN@3.asm"
    include "SHADOW_PLY.asm"
    include "SHADOW_BOARD.asm"
    include "BANK_EVAL.asm"
    include "BANK_StateMachine@1#1.asm"
    include "BANK_StateMachine@1#2.asm"
    include "piece_graphics.asm"
    include "BANK_GENERIC@2.asm"
    include "GFX1.asm"
    include "GFX2.asm"
    include "GFX3.asm"
    include "GFX4.asm"
    include "NEGAMAX@1.asm"

    include "PIECE_MACROS.asm"

    include "PIECE_HANDLER@1#1.asm"
    include "PIECE_HANDLER@1#2.asm"
    include "BANK_3.asm"

    include "BANK_LAST.asm"

;---------------------------------------------------------------------------------------------------
;EOF
