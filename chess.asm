; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


TIA_BASE_ADDRESS = $40

                processor 6502
                include "vcs.h"
                include "macro.h"
                include "piece_defines.h"

ORIGIN          SET 0
ORIGIN_RAM      SET 0

                include "segtime.asm"

;FIXED_BANK             = 3 * 2048           ;-->  8K ROM tested OK
;FIXED_BANK              = 7 * 2048          ;-->  16K ROM tested OK
FIXED_BANK             = 15 * 2048           ; ->> 32K
;FIXED_BANK             = 31 * 2048           ; ->> 64K
;FIXED_BANK             = 239 * 2048         ;--> 480K ROM tested OK (KK/CC2 compatibility)
;FIXED_BANK             = 127 * 2048         ;--> 256K ROM tested OK
;FIXED_BANK             = 255 * 2048         ;--> 512K ROM tested OK (CC2 can't handle this)

YES                     = 1
NO                      = 0

;===================================
FINAL_VERSION                   = NO           ; this OVERRIDES any selections below and sets everything correct for a final release
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
RESERVED_FOR_STACK              = 12            ; bytes guaranteed not overwritten by variable use

DIRECTION_BITS              = %111              ; for ManLastDirection

;------------------------------------------------------------------------------

PLUSCART = YES

;------------------------------------------------------------------------------


CHESSBOARD_ROWS            = 8                 ; number of ROWS of chessboard
LINES_PER_CHAR              = 24                ; MULTIPLE OF 3 SO RGB INTERFACES CHARS OK
PIECE_SHAPE_SIZE            = 72                ; 3 PF bytes x 24 scanlines

SET_BANK                    = $3F               ; write address to switch ROM banks
SET_BANK_RAM                = $3E               ; write address to switch RAM banks


RAM_3E                      = $1000
RAM_SIZE                    = $400
RAM_WRITE                   = $400              ; add this to RAM address when doing writes


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


;------------------------------------------------------------------------------
; MACRO definitions


ROM_BANK_SIZE               = $800

            MAC NEWBANK ; bank name
                SEG {1}
                ORG ORIGIN
                RORG $F000
BANK_START      SET *
{1}             SET ORIGIN / 2048
ORIGIN          SET ORIGIN + 2048
_CURRENT_BANK   SET {1}
            ENDM

            MAC DEFINE_1K_SEGMENT ; {seg name}
                ALIGN $400
SEGMENT_{1}     SET *
BANK_{1}        SET _CURRENT_BANK
            ENDM

            MAC CHECK_BANK_SIZE ; name
.TEMP = * - BANK_START
    ECHO {1}, "(2K) SIZE = ", .TEMP, ", FREE=", ROM_BANK_SIZE - .TEMP
#if ( .TEMP ) > ROM_BANK_SIZE
    ECHO "BANK OVERFLOW @ ", * - ORIGIN
    ERR
#endif
            ENDM


            MAC CHECK_HALF_BANK_SIZE ; name
    ; This macro is for checking the first 1K of ROM bank data that is to be copied to RAM.
    ; Note that these ROM banks can contain 2K, so this macro will generally go 'halfway'
.TEMP = * - BANK_START
    ECHO {1}, "(1K) SIZE = ", .TEMP, ", FREE=", ROM_BANK_SIZE/2 - .TEMP
#if ( .TEMP ) > ROM_BANK_SIZE/2
    ECHO "HALF-BANK OVERFLOW @ ", * - ORIGIN
    ERR
#endif
            ENDM



    ;--------------------------------------------------------------------------
    ; Macro inserts a page break if the object would overlap a page

    MAC OPTIONAL_PAGEBREAK ; { string, size }
        LIST OFF
        IF (>( * + {2} -1 )) > ( >* )
EARLY_LOCATION  SET *
            ALIGN 256
            ECHO "PAGE BREAK INSERTED FOR ", {1}
            ECHO "REQUESTED SIZE = ", {2}
            ECHO "WASTED SPACE = ", *-EARLY_LOCATION
            ECHO "PAGEBREAK LOCATION = ", *
        ENDIF
        LIST ON
    ENDM


    MAC CHECK_PAGE_CROSSING
        LIST OFF
#if ( >BLOCK_END != >BLOCK_START )
    ECHO "PAGE CROSSING @ ", BLOCK_START
#endif
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


    MAC CHECKPAGE_BNE
        LIST OFF
        IF 0;>(. + 2) != >{1}
            ECHO ""
            ECHO "ERROR: different pages! (", {1}, ",", ., ")"
            ECHO ""
            ERR
        ENDIF
        LIST ON
            bne     {1}
    ENDM

    MAC CHECKPAGE_BPL
        LIST OFF
        IF (>(.+2 )) != >{1}
            ECHO ""
            ECHO "ERROR: different pages! (", {1}, ",", ., ")"
            ECHO ""
            ERR
        ENDIF
        LIST ON
            bpl     {1}
    ENDM

  MAC ALIGN_FREE
FREE SET FREE - .
    align {1}
FREE SET FREE + .
    echo "@", ., ":", FREE
  ENDM

    ;--------------------------------------------------------------------------

    MAC VECTOR              ; just a word pointer to code
        .word {1}
    ENDM


    MAC DEFINE_SUBROUTINE               ; name of subroutine
BANK_{1}        = _CURRENT_BANK         ; bank in which this subroutine resides
                SUBROUTINE              ; keep everything local
{1}                                     ; entry point
    ENDM



    ;--------------------------------------------------------------------------

    MAC NEWRAMBANK ; bank name
                SEG.U {1}
                ORG ORIGIN_RAM
                RORG RAM_3E
BANK_START      SET *
{1}             SET ORIGIN_RAM / RAM_SIZE
ORIGIN_RAM      SET ORIGIN_RAM + RAM_SIZE
    ENDM

; TODO - fix - this is faulty....
    MAC VALIDATE_RAM_SIZE
.RAM_BANK_SIZE SET * - RAM_3E
        IF .RAM_BANK_SIZE > RAM_SIZE
            ECHO "RAM BANK OVERFLOW @ ", (* - RAM_3E)
            ERR
        ENDIF
    ENDM


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


;------------------------------------------------------------------------------

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
    ; EACH BANK HAS A READ-ADDRESS AND A WRITE-ADDRESS, WITH 2k TOTAL

                NEWRAMBANK BANK_SCREENMARKII1

    ; NOTE: THIS BANK JUST *LOOKS* EMPTY.
    ; It actually contains everything copied from the ROM copy of the ROW RAM banks.
    ; The variable definitions are also in that ROM bank (even though they're RAM :)

SCREEN_BITMAP_SIZE      = 4 * LINES_PER_CHAR

    ; These banks (there are #CHESSBOARD_ROWS of them) hold a RAM copy of the screen draw
    ; code.  This code is self-modifying, in that the colour values for each scanline
    ; are set to NTSC or PAL values on startup -- thus, the single binary can run
    ; on either format system.  The main purpose for copying the draw code to RAM,
    ; though, is to free up space in the fixed bank (which is incredibly valuable).

    ; A neat feature of having multiple copies of the same code in different RAM banks
    ; is that we can use that code to switch between banks, and the system will happily
    ; execute the next instruction from the newly switched-in bank without a problem.

    ; Now we have the actual graphics data for each of the rows.  This consists of an
    ; actual bitmap (in exact PF-style format, 6 bytes per line) into which the
    ; character shapes are masked/copied. The depth of the character shapes may be
    ; changed by changing the #LINES_PER_CHAR value.  Note that this depth should be
    ; a multiple of 3, so that the RGB scanlines match at character joins.

    ; The next part of the graphics data is a bitmap sprite buffer -- space for two
    ; sprites' graphics shape and colour data.  The shape and colour may be set as
    ; part of the draw routine *every* scanline (though the system currently uses
    ; one colour shared between both players).

                VALIDATE_RAM_SIZE

    ; We have one bank for each screen row.  These banks are duplicates of the above,
    ; accessed via the above labels but with the appropriate bank switched in.

    ;------------------------------------------------------------------------------

    REPEAT (CHESSBOARD_ROWS) - 1
        NEWRAMBANK .DUMMY
        VALIDATE_RAM_SIZE
    REPEND

;---------------------------------------------------------------------------------------------------

    NEWRAMBANK BANK_CHESSBOARD
Chessboard      ds 64
    VALIDATE_RAM_SIZE

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

            NEWRAMBANK BANK_SCREEN
; VARS DEFINED IN ROM_SHADOW_OF_SCREEN
            VALIDATE_RAM_SIZE


                NEWRAMBANK BANK_DRAW_BUFFERS
; VARS DEFINED IN ROM_SHADOW_OF_BANK_DRAW_BUFFERS
; SELF-MODIFYING SUBROUTINES MAY BE PRESENT IN THIS BANK TOO!
                VALIDATE_RAM_SIZE

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

                NEWRAMBANK BANK_SCORING
; VARS DEFINED IN ROM_SHADOW_OF_BANK_SCORING
; SELF-MODIFYING SUBROUTINES MAY BE PRESENT IN THIS BANK TOO!
                VALIDATE_RAM_SIZE

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

                NEWRAMBANK BANK_DECODE_LEVEL
; VARS DEFINED IN BANK_DECODE_LEVEL_SHADOW
; SELF-MODIFYING SUBROUTINES MAY BE PRESENT IN THIS BANK TOO!
                VALIDATE_RAM_SIZE

    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------


    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

                NEWRAMBANK BANK_BOARD

    ; Now the interesting 'BOARD' -- which in reality is a free-form system of M*N
    ; rows and columns.  We need to reserve enough RAM for the board's entirety, but
    ; don't really care much how it overlaps the 1K bank limit.  The code accessing
    ; the board *MUST* calculate and take account of the correct RAM bank to switch
    ; when accessing.

    ; The system is fairly free-form, in that it rearranges the memory and tables
    ; automatically based on the sizes set in these constants. The board may overlay
    ; MULTIPLE banks -- just as long as any particular LINE does not cross a bank
    ; we're doing OK.

    ; NOTE: Assumption is that board lines CANNOT CROSS page boundaries.

; now fits into one single bank (if we don't reserve too much space for code)


    ;------------------------------------------------------------------------------
    ;##############################################################################
    ;------------------------------------------------------------------------------

RND_EOR_VAL = $FE ;B4

    MAC	NEXT_RANDOM
        lda	rnd
        lsr
        bcc .skipEOR
        eor #RND_EOR_VAL
.skipEOR    sta rnd
    ENDM

;--------------------------------------------------------------------------------

;ORIGIN      SET 0

            include "BANK_GENERIC.asm"
            include "BANK_ROM_SHADOW_SCREEN.asm"
            include "BANK_INITBANK.asm"         ; MUST be after banks that include levels -- otherwise MAX_LEVELBANK is not calculated properly
            include "BANK_CHESS_INCLUDES.asm"
            include "titleScreen.asm"
            include "engine6502.asm"
            include "common_variables.asm"
            include "Handler_KING.asm"
            include "Handler_QUEEN.asm"

    ; MUST BE LAST...
            include "BANK_FIXED.asm"

            ;END
