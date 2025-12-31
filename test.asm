    processor 6502
 
 
  include "vcs.h"
  include "macro.h"


NTSC_TIM = 1

    org $1000


Reset

    CLEAN_START

    ldx #128
.copyToZP
    lda RAMRoutine,x
    sta $80,x
    dex
    bpl .copyToZP

    lda #$0E
    sta COLUPF
;    lda #$94
;    sta COLUBK


    lda #2
    sta CTRLPF
    lda #$0E
    sta COLUP0
    lda #$94
    sta COLUP1
    sta COLUBK

    jmp frame_loop-RAMRoutine+$80






RAMRoutine

ADJUST = -RAMRoutine+$80



PlusLogoAnimation

    .byte %00000000,%01000100,%10010010,%10111010,%10010010,%01000100,0,0
    .byte 10,11,12,13
    .byte 10,11,12,13
    .byte 20,21,22,23
    .byte 20,21,22,23
    .byte 30,13,32,33
    .byte 30,13,32,33

PlusLogo .byte 0,0,0,0,0,0
logoBase .byte 0

EndWaitCartRoutine
	  .byte $0	



frame_loop
; Enable VBLANK (disable output)
;  	lda #2
;  	sta VBLANK
; At the beginning of the frame we set the VSYNC bit...
;  	sta VSYNC
; And hold it on for 3 scanlines...
;  	sta WSYNC
;  	sta WSYNC
;  	sta WSYNC
; Now we turn VSYNC off.
;  	lda #0
;  	sta VSYNC
;

    VERTICAL_SYNC


; Now we need 37 lines of VBLANK...	
  	ldx #37
lVBLANK sta WSYNC
  	dex
  	bne lVBLANK
; Re-enable output (disable VBLANK)	
  	;lda #0
  	stx VBLANK
	
  IF NTSC_TIM
	  ldy #32	          ; 32 scanlines, total 192(ntsc, pal60)
  ELSE
    ldy #42           ; 42 scanlines, total 242(pal)
  ENDIF

scan1
  	sta WSYNC
	  dey
	  bne scan1


    ; animate - copy the shape data for the frame to the generic logo buffer

    lda logoBase+ADJUST
    clc
    adc #8
    sta logoBase+ADJUST

    lsr
    lsr
    and #%11000
    ora #$80
    sta SML+ADJUST+1

;    lda PlusLogoAnimation+ADJUST,x
;    sta PlusLogo+ADJUST
;    sta PlusLogo+6+ADJUST
;    lda PlusLogoAnimation+1+ADJUST,x
;    sta PlusLogo+1+ADJUST
;    sta PlusLogo+5+ADJUST
;    lda PlusLogoAnimation+2+ADJUST,x
;    sta PlusLogo+2+ADJUST
;    sta PlusLogo+4+ADJUST
;    lda PlusLogoAnimation+3+ADJUST,x
;    sta PlusLogo+3+ADJUST



    ldx #6 ;#vertical dots in shape

drawLogo

    ldy #9 ;HEIGHT


SML    lda 0,x


drawLogoScan

	sta WSYNC
    sta PF1

    dey
    bne drawLogoScan

    dex
    bpl drawLogo

    sty PF1

	
  IF NTSC_TIM
	  ldx #136 ; 136 scanlines
  ELSE
    ldx #176 ; 176 scanlines
  ENDIF

scan3
  	sta WSYNC
  	dex
  	bne scan3

; Enable VBLANK again
  	lda #2
  	sta VBLANK
; 30 lines of overscan to complete the frame
  	ldx #30
lvover	sta WSYNC
  	dex
  	bne lvover

;check if firmware back
  	lda $1000
  	cmp #$d8 ; d8 8d for cart
  	bne frame_loop
	
;  	lda StatusByteReboot
;  	bne reboot
	  rts

reboot

;	  ldx #$3E
;	  lda #0
;add2
;	  sta $00,x		;Clear TIA ($00-$3f)
;	  dex
;      bpl add2
;	  cpx #$3f
;	  bcc add2


	  ldx #$FD		;Set stack pointer to $fd
	  txs
; tell cart we are ready for switch
;    lda #RebootCommand
;	  sta SendCartCommand
;	  lda #0
;	  sta WSYNC
;	  sta WSYNC
	  jmp ($fffc)



    org $1FFC
 .word Reset
 .word Reset