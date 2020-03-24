;
; syspage.inc
;
; By Alex Herbert, 2004
;




;
; Call eeprom_readsys at program start to load the
; TV settings from EEPROM into the variable tv_mode.
;
; Call eeprom_writesys to save tv_mode to EEPROM
; after switching modes.
;
; tv_mode:
;       bit 7 - 0=NTSC, 1=PAL
;       bit 6 - 0=60Hz, 1=50Hz
;       bit 5 - Always 0
;       bit 4 - Always 0
;       bit 3 - Always 0
;       bit 2 - Always 0
;       bit 1 - Always 0
;       bit 0 - Always 0
;
; It is not necessary that your application supports
; all mode combinations.
;



eeprom_readsys
        lda     #$00                    ; Default TV mode = NTSC
        sta     tv_mode

        ; Fisrt we set the EEPROM's memory pointer
        ; to $0000.

        jsr     i2c_startwrite
        bcs     eeprom_sysfail          ; Device not attached?
        lda     #$00
        jsr     i2c_txbyte
        lda     #$00
        jsr     i2c_txbyte
        jsr     i2c_stopwrite

        ; Now we check for the "ATARIVOX" signature in
        ; the first 8 bytes.

        jsr     i2c_startread

        ldx     #$00
eereadsys_loop
        jsr     i2c_rxbyte
        cmp     avoxsys_filename,x
        bne     eereadsys_notvalid      ; Mismatch?
        inx
        cpx     #$08
        bne     eereadsys_loop

        ; Signature found, so the next byte holds the
        ; TV mode.

        jsr     i2c_rxbyte
        and     #$c0
        sta     tv_mode

        jmp     i2c_stopread            ; Done!


eereadsys_notvalid
        ; If the signature was not found then we want
        ; to create a signature and set the default
        ; TV mode

        jsr     i2c_stopread            ; End the read started above


eeprom_writesys
        ; Set EEPROM addres to $0000.

        jsr     i2c_startwrite
        bcs     eeprom_sysfail          ; Device not attached?
        lda     #$00
        jsr     i2c_txbyte
        lda     #$00
        jsr     i2c_txbyte

        ; Write "ATARIVOX" signature to first 8 bytes.

        ldx     #$00
eewritesys_loop
        lda     avoxsys_filename,x
        jsr     i2c_txbyte
        inx
        cpx     #$08
        bne     eewritesys_loop

        ; Write TV mode

        lda     tv_mode
        and     #$c0
        jsr     i2c_txbyte

eeprom_sysfail
        jmp     i2c_stopwrite           ; Done!



avoxsys_filename
        dc.b    "ATARIVOX"


