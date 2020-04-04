
TIA_BASE_ADDRESS = $40

    processor 6502
    include "vcs.h"
    include "macro.h"

ORIGIN              SET 0
ORIGIN_RAM          SET 0

FIXED_BANK          = 3 * 2048
ROM_BANK_SIZE       = $800

SET_BANK            = $3F               ; write address to switch ROM banks
SET_BANK_RAM        = $3E               ; write address to switch RAM banks

RAM_3E              = $1000
RAM_SIZE            = $400
RAM                 = $400              ; write modifier for RAM access


;---------------------------------------------------------------------------------------------------

    MAC NEWBANK ; bank name
                    SEG {1}
                    ORG ORIGIN
                    RORG $F000
BANK_START          SET *
{1}                 SET ORIGIN / 2048
ORIGIN              SET ORIGIN + 2048
_CURRENT_BANK       SET {1}
            ENDM


;---------------------------------------------------------------------------------------------------

   MAC NEWRAMBANK ; bank name
    ; {1}       bank name
    ; {2}       RAM bank number

                SEG.U {1}
                ORG ORIGIN_RAM
                RORG RAM_3E
BANK_START      SET *
RAMBANK_{1}     SET ORIGIN_RAM / RAM_SIZE
_CURRENT_RAMBANK SET RAMBANK_{1}
ORIGIN_RAM      SET ORIGIN_RAM + RAM_SIZE
    ENDM


;---------------------------------------------------------------------------------------------------

    MAC DEF               ; name of subroutine
BANK_{1}        SET _CURRENT_BANK         ; bank in which this subroutine resides
{1}                                     ; entry point
FUNCTION_NAME   SET {1}
    ENDM

;---------------------------------------------------------------------------------------------------

    MAC sta@RAM ;{}
        sta [RAM]+{0}
    ENDM

;---------------------------------------------------------------------------------------------------

                SEG.U variables
                ORG $80

__sourceBank    ds 1

;---------------------------------------------------------------------------------------------------
; DEFINE some space in the RAM area.
; This is a shadow bank into which the appropriate ROM bank is binary-copied

    NEWRAMBANK ROM_SHADOW               ; this is the RAM shado of the ROM bank!


;---------------------------------------------------------------------------------------------------
; and now the ROM shadow - this is copied to a RAM (1K) bank

    NEWBANK BANK_PLY                   ; ROM SHADOW


testVariable    ds 1                   ; this is the variable we will try to write

    ; the write will ONLY work if we have a RAM bank switched in!


;---------------------------------------------------------------------------------------------------
;#########################################  FIXED BANK  ############################################
;---------------------------------------------------------------------------------------------------

ORIGIN              SET FIXED_BANK

                    NEWBANK THE_FIXED_BANK
                    RORG $f800

    DEF Reset
    SUBROUTINE

                    sei
                    cld
                    ldx #$FF
                    txs


                    lda #BANK_PLY
                    ldy #0                          ; destination RAM bank
                    jsr CopyShadowROMtoRAM


    ; at this stage we now have a binary copy of the bank "BANK_PLY" in the first 1K RAM bank
    ; so let's test a write... disable the following to FAIL to switch in the RAM bank before write

                    lda #0
                    sta SET_BANK                    ; <-- this one will crash
;                    sta SET_BANK_RAM                ; <-- this one will work


    ; now try a write

                    sta@RAM testVariable

.halt               jmp .halt



    DEF CopyShadowROMtoRAM
    SUBROUTINE

    ; Copy a whole 1K ROM SHADOW into a destination RAM 1K bank
    ; used to setup callable RAM code from ROM templates

    ; x = source ROM bank
    ; y = destination RAM bank (preserved)

                    stx __sourceBank

                    ldx #0
.copyPage           lda __sourceBank
                    sta SET_BANK

                    lda $F000,x
                    pha
                    lda $F100,x
                    pha
                    lda $F200,x
                    pha
                    lda $F300,x

                    sty SET_BANK_RAM

                    sta@RAM $F300,x
                    pla
                    sta@RAM $F200,x
                    pla
                    sta@RAM $F100,x
                    pla
                    sta@RAM $F000,x

                    dex
                    bne .copyPage
                    rts


;---------------------------------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the fixed bank (last 2K of any ROM image in "3E" scheme)

    SEG InterruptVectors
    ORG FIXED_BANK + $7FC
    RORG $7ffC

                    .word Reset                     ; RESET
                    .word Reset                     ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
; EOF


;eof
