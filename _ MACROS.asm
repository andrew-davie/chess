; MACROS.asm
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
;       REF fnc
;       REF fnd
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


;---------------------------------------------------------------------------------------------------

    ; Finalise the declaration block for local variables
    ; {1} = name of the function for which this block is defined
    MAC VEND
    ; register the end of variables for this function

VAREND_{1} = TEMPORARY_VAR
;V2_._FUNCTION_NAME = TEMPORARY_VAR
    ENDM


;---------------------------------------------------------------------------------------------------

    ; Note a reference to this function by an external function
    ; The external function's VEND block is used to guarantee that variables for
    ; the function we are declaring will start AFTER all other variables in all referencing blocks

    MAC REF ; {1}
        IF VAREND_{1} > TEMPORARY_VAR
TEMPORARY_VAR SET VAREND_{1}
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

    ; Define a temporary variable for use in a subroutine
    ; Will allocate appropriate bytes, and also check for overflow of the available overlay buffer

    MAC VAR ; { name, size }
{1} = TEMPORARY_VAR
TEMPORARY_VAR SET TEMPORARY_VAR + TEMPORARY_OFFSET + {2}

OVERLAY_DELTA SET TEMPORARY_VAR - Overlay
        IF OVERLAY_DELTA > MAXIMUM_REQUIRED_OVERLAY_SIZE
MAXIMUM_REQUIRED_OVERLAY_SIZE SET OVERLAY_DELTA
        ENDIF
        IF OVERLAY_DELTA + Overlay >= TOP_OF_STACK
VNAME   SETSTR {1}
            ECHO "Temporary Variable", VNAME, "overflow!"
            ERR
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

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
_CURRENT_BANK_TYPE  SET _TYPE_ROM
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC CHECK_BANK_SIZE
.TEMP = * - _BANK_START
        ECHO "ROM bank #", [_ORIGIN/_ROM_BANK_SIZE]d, _LAST_BANK, "size =", .TEMP, "free =", [_ROM_BANK_SIZE - .TEMP - 1]d
        IF ( .TEMP ) > _ROM_BANK_SIZE
            ECHO "BANK OVERFLOW @", _LAST_BANK, " size=", * - _ORIGIN
            ERR
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC CHECK_RAM_BANK_SIZE
.TEMP = * - _BANK_START
        ECHO "RAM bank #", [ORIGIN_RAM/_RAM_BANK_SIZE]d, _LAST_BANK, "size = ", .TEMP, "free =", _RAM_BANK_SIZE - .TEMP - 1
        IF ( .TEMP ) > _RAM_BANK_SIZE
            ECHO "BANK OVERFLOW @", _LAST_BANK, " size=", * - ORIGIN_RAM
            ERR
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

_TYPE_RAM = 0
_TYPE_ROM = 1

    MAC END_BANK
        IF _CURRENT_BANK_TYPE = _TYPE_RAM
            CHECK_RAM_BANK_SIZE
        ELSE
            CHECK_BANK_SIZE
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

    MACRO RAMBANK ; {bank name}

        SEG.U RAM_{1}
        ORG ORIGIN_RAM
        RORG _BANK_ADDRESS_ORIGIN
_BANK_START         SET *
_CURRENT_RAMBANK    SET (ORIGIN_RAM / _RAM_BANK_SIZE)
RAMBANK_{1}         SET _BANK_SLOT + _CURRENT_RAMBANK
ORIGIN_RAM          SET ORIGIN_RAM + _RAM_BANK_SIZE
_LAST_BANK          SETSTR {1}
_CURRENT_BANK_TYPE  SET _TYPE_RAM
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

    MAC JUMP ; function name
        IF SLOT_{1} == _BANK_SLOT
FNAME SETSTR {1}
            ECHO ""
            ECHO "ERROR: Incompatible slot for jump to function", FNAME
            ECHO "Cannot switch bank in use for ", FNAME
            ERR
        ENDIF
        lda #BANK_{1}
        sta SET_BANK
        jmp {1}
    ENDM


;---------------------------------------------------------------------------------------------------
; Macro inserts a page break if the object would overlap a page

    MAC OPTIONAL_PAGEBREAK ; { labelString, size }

        IF (>( * + {2} -1 )) > ( >* )
.EARLY_LOCATION  SET *
            ALIGN 256
            ECHO "Page break for", {1}, "wasted", [* - .EARLY_LOCATION]d, "bytes"
        ENDIF
    ENDM


;---------------------------------------------------------------------------------------------------

; @author Fred Quimby
; same as bAtari Basic rnd

RND_EOR_VAL = $B4

    MAC	NEXT_RANDOM

        lda	rnd
        lsr
        bcc .skipEOR
        eor #RND_EOR_VAL
.skipEOR    sta rnd

    ENDM


;---------------------------------------------------------------------------------------------------
; Defines a variable of the given size, making sure it doesn't cross a page

    MAC VARIABLE ; {name, size}

.NAME SETSTR {1}
    OPTIONAL_PAGEBREAK .NAME, {2}
{1} ds {2}

    ENDM


;---------------------------------------------------------------------------------------------------

;TODO - check

    MAC ALLOCATE ; {label}, {size}

.NAME SETSTR {1}    
    OPTIONAL_PAGEBREAK .NAME, {2}
    DEF {1}

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


;---------------------------------------------------------------------------------------------------

    MAC SWAP

        lda sideToMove
        eor #SWAP_SIDE|HUMAN
        sta sideToMove

    ENDM


;---------------------------------------------------------------------------------------------------
; RAM accessor macros
; ALL RAM usage (reads and writes) should use these
; They automate the write offset address addition, and make it clear what memory is being accessed


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

    MAC ora@RAM
        ora {0}
    ENDM

    MAC eor@RAM
        eor {0}
    ENDM

    MAC and@RAM
        and {0}
    ENDM

    MACRO cpx@PLY
        cpx [RAM] + {0}
    ENDM
    
;---------------------------------------------------------------------------------------------------

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
        sta platform                    ; P1 difficulty --> TV system (0=NTSC, 1=PAL)

    ENDM


;---------------------------------------------------------------------------------------------------

    MAC TIMECHECK ; {ident}, {branch if out of time}

        lda INTIM
        cmp #SPEEDOF_{1}
        bcc {2}

    ENDM


;---------------------------------------------------------------------------------------------------

    MAC TIMING ; {label}, {cycles}

SPEEDOF_{1} = ({2}/64) + 1

    ENDM


;---------------------------------------------------------------------------------------------------
;EOF
