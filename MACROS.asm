; MACROS.asm


;---------------------------------------------------------------------------------------------------

    MAC DEF ; {name of subroutine}

; Declare a subroutine
; Sets up a whole lot of helper stuff
;   slot and bank equates
;   local variable setup

SLOT_{1}        SET _BANK_SLOT
BANK_{1}        SET SLOT_{1} + _CURRENT_BANK         ; bank in which this subroutine resides
{1}                                     ; entry point
TEMPORARY_VAR SET Overlay
TEMPORARY_OFFSET SET 0
VAR_BOUNDARY_{1} SET TEMPORARY_OFFSET
_FUNCTION_NAME SETSTR {1}
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC RAMDEF ; {name of subroutine}

    ; Just an alternate name for "DEF" that makes it clear the subroutine is in RAM

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
; Temporary local variables
; usage:
;
;   DEF fna
;       REFER fnc
;       REFER fnd
;       VAR localVar1,1
;       VAR ptr,2
;       VEND fna
;
; The above declares a functino named 'fna'
; The function declares two local variables, 'localVar1' (1 byte) and 'ptr' (2 bytes)
; These variables are given an address in the overlay area which does NOT overlap any of
; the local variables which are declared in the referring functions 'fnc' and 'fnd'
; Although the local variables are available to other functions (i.e., global in scope), care
; should be taken NOT to use them in other functions unless absolutely necessary and required.
; To share local variables between functions, they should be (re)declared in both so that they
; have exactly the same addresses.



; The relative offset into the overlay area for the next variable declaration...
TEMPORARY_OFFSET SET 0



    ; Finalise the declaration block for local variables
    ; {1} = name of the function for which this block is defined
    MAC VEND
    ; register the end of variables for this function

VAREND_{1} = TEMPORARY_VAR
;V2_._FUNCTION_NAME = TEMPORARY_VAR
    ENDM


    ; Note a reference to this function by an external function
    ; The external function's VEND block is used to guarantee that variables for
    ; the function we are declaring will start AFTER all other variables in all referencing blocks

    MAC REF ; {1}
        IF VAREND_{1} > TEMPORARY_VAR
TEMPORARY_VAR SET VAREND_{1}
        ENDIF
    ENDM



    ; Define a temporary variable for use in a subroutine
    ; Will allocate appropriate bytes, and also check for overflow of the available overlay buffer

    MAC VAR ; { name, size }
;        ;LIST OFF
{1} = TEMPORARY_VAR
TEMPORARY_VAR SET TEMPORARY_VAR + TEMPORARY_OFFSET + {2}

OVERLAY_DELTA SET TEMPORARY_VAR - Overlay
        IF OVERLAY_DELTA > MAXIMUM_REQUIRED_OVERLAY_SIZE
MAXIMUM_REQUIRED_OVERLAY_SIZE SET OVERLAY_DELTA
        ENDIF
        IF OVERLAY_DELTA + Overlay >= TOP_OF_STACK
            LIST ON
            VNAME   SETSTR {1}
            ECHO "Temporary Variable", VNAME, "overflow!"
            ERR
            ECHO "Temporary Variable overlow!"
        ENDIF
        LIST ON
    ENDM


    MAC ROMBANK ; bank name
        SEG ROM_{1}
        ORG _ORIGIN
        RORG _BANK_ADDRESS_ORIGIN
_BANK_START         SET *
{1}_START           SET *
_CURRENT_BANK       SET (_ORIGIN - _FIRST_BANK ) / _ROM_BANK_SIZE
ROMBANK_{1}         SET _BANK_SLOT + _CURRENT_BANK
_ORIGIN             SET _ORIGIN + _ROM_BANK_SIZE
_LAST_BANK          SETSTR {1}
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC CHECK_BANK_SIZE
.TEMP = * - _BANK_START
        ECHO _LAST_BANK, "SIZE =", .TEMP, ", FREE=", _ROM_BANK_SIZE - .TEMP
        IF ( .TEMP ) > _ROM_BANK_SIZE
            ECHO "BANK OVERFLOW @", _LAST_BANK, " size=", * - ORIGIN
            ERR
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC CHECK_RAM_BANK_SIZE
.TEMP = * - _BANK_START
        ECHO _LAST_BANK, "SIZE =", .TEMP, ", FREE=", _RAM_BANK_SIZE - .TEMP
        IF ( .TEMP ) > _RAM_BANK_SIZE
            ECHO "BANK OVERFLOW @", _LAST_BANK, " size=", * - ORIGIN
            ERR
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC RAMBANK ; {bank name}

        SEG.U RAM_{1}
        ORG ORIGIN_RAM
        RORG _BANK_ADDRESS_ORIGIN
_BANK_START         SET *
_CURRENT_RAMBANK    SET (ORIGIN_RAM / _RAM_BANK_SIZE)
RAMBANK_{1}         SET _BANK_SLOT + _CURRENT_RAMBANK
ORIGIN_RAM          SET ORIGIN_RAM + _RAM_BANK_SIZE
_LAST_BANK          SETSTR {1}

    ENDM


;---------------------------------------------------------------------------------------------------

    ; Failsafe call of function in another bank
    ; This will check the slot #s for current, call to make sure they're not the same!

    MAC CALL ; function name
        IF SLOT_{1} == _BANK_SLOT
FNAME SETSTR {1}
            ECHO ""
            ECHO "ERROR: Incompatible slot for call to function", FNAME
            ECHO "Cannot switch bank in use for ", FNAME
            ERR
        ENDIF
        lda #BANK_{1}
        sta SET_BANK
        jsr {1}
    ENDM


;---------------------------------------------------------------------------------------------------
; RAM accessor macros
; ALL RAM usage (reads and writes) should use these
; They automate the write offset address addition, and make it clear what memory is being accessed


    MAC sta@RAM ;{}
        sta [RAM]+{0}
    ENDM

    MAC stx@RAM ;{}
        stx [RAM]+{0}
    ENDM

    MAC sty@RAM ;{}
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


    MAC adc@RAM ;{}
        lda {0}
    ENDM

    MAC sbc@RAM ;{}
        lda {0}
    ENDM

    MAC cmp@RAM ;{}
        cmp {0}
    ENDM


;---------------------------------------------------------------------------------------------------

            MAC OVERLAY ; {name}
    SEG.U OVERLAY_{1}
    org Overlay
            ENDM


;---------------------------------------------------------------------------------------------------

    MAC VALIDATE_OVERLAY
;        ;LIST OFF
        #if * - Overlay > OVERLAY_SIZE
            ERR
        #endif
        LIST ON
    ENDM


;---------------------------------------------------------------------------------------------------
; Macro inserts a page break if the object would overlap a page

    MAC OPTIONAL_PAGEBREAK ; { string, size }
;        ;LIST OFF
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


;---------------------------------------------------------------------------------------------------

RND_EOR_VAL = $FE ;B4

    MAC	NEXT_RANDOM
        lda	rnd
        lsr
        bcc .skipEOR
        eor #RND_EOR_VAL
.skipEOR    sta rnd
    ENDM


;---------------------------------------------------------------------------------------------------


    MAC SET_PLATFORM
; 00 = NTSC
; 01 = NTSC
; 10 = PAL-50
; 11 = PAL-60
        lda SWCHB                       ; 4
        and #%11000000                  ; 2     make sure carry is clear afterwards
        asl                             ; 2
        rol                             ; 2
        rol                             ; 2
#if NTSC_MODE = NO
        eor #PAL
#endif
        sta Platform                    ; 3 = 15 P1 difficulty ──▷ TV system (0=NTSC, 1=PAL)
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC NOP_B       ; unused
        .byte   $82
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC NOP_W
        .byte   $0c
    ENDM


;---------------------------------------------------------------------------------------------------
;EOF
