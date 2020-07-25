;
; vox_test.asm
;
;
; By Alex Herbert, 2004
;



        processor       6502



; TIA Registers (Write)
VSYNC   equ     $00
VBLANK  equ     $01
WSYNC   equ     $02
RSYNC   equ     $03
NUSIZ0  equ     $04
NUSIZ1  equ     $05
COLUP0  equ     $06
COLUP1  equ     $07
COLUPF  equ     $08
COLUBK  equ     $09
CTRLPF  equ     $0a
REFP0   equ     $0b
REFP1   equ     $0c
PF0     equ     $0d
PF1     equ     $0e
PF2     equ     $0f
RESP0   equ     $10
RESP1   equ     $11
RESM0   equ     $12
RESM1   equ     $13
RESBL   equ     $14
AUDC0   equ     $15
AUDC1   equ     $16
AUDF0   equ     $17
AUDF1   equ     $18
AUDV0   equ     $19
AUDV1   equ     $1a
GRP0    equ     $1b
GRP1    equ     $1c
ENAM0   equ     $1d
ENAM1   equ     $1e
ENABL   equ     $1f
HMP0    equ     $20
HMP1    equ     $21
HMM0    equ     $22
HMM1    equ     $23
HMBL    equ     $24
VDELP0  equ     $25
VDELP1  equ     $26
VDELBL  equ     $27
RESMP0  equ     $28
RESMP1  equ     $29
HMOVE   equ     $2a
HMCLR   equ     $2b
CXCLR   equ     $2c


; TIA Registers (Read)
CXM0P   equ     $00
CXM1P   equ     $01
CXP0FB  equ     $02
CXP1FB  equ     $03
CXM0FB  equ     $04
CXM1FB  equ     $05
CXBLPF  equ     $06
CXPPMM  equ     $07
INPT0   equ     $08
INPT1   equ     $09
INPT2   equ     $0a
INPT3   equ     $0b
INPT4   equ     $0c
INPT5   equ     $0d


; RIOT Registers
SWCHA   equ     $0280
SWACNT  equ     $0281

SWCHB   equ     $0282
SWBCNT  equ     $0283

INTIM   equ     $0284
TIMINT  equ     $0285

TIM1T   equ     $0294
TIM8T   equ     $0295
TIM64T  equ     $0296
T1024T  equ     $0297




; Speakjet Driver

        include "speakjet.inc"




; Macros

        mac     WAIT_TIMINT
.1      bit     TIMINT
        bpl     .1
        sta     WSYNC
        endm



        mac     WAIT_HBLS
        ldx     {1}
.1      dex
        sta     WSYNC
        bne     .1
        endm




; Variables

        seg.u   bss
        org     $0080


frame           ds      1
temp            ds      1
switch_states   ds      1
switch_edges    ds      1

speech_addr     ds      2




; Code/Data

        seg     code
        org     $f000,$ff


        ;ds 1*1024

; Speech Data

fire_speech
        dc.b    31,253
        dc.b    $ff

up_speech
        dc.b    31,191,131,8,187,191,129,143,2,2
        dc.b    191,131,8,187,191,129,143,2,2
        dc.b    147,14,136,8,141,8,191,162,8,190,148,8,128,31
        dc.b    $ff
down_speech
        dc.b    31,22,110,23,1,215,6
        dc.b    174,154,7,141,7,165,7,151,6,215,6
        dc.b    174,154,7,141,7,165,7,151,6,215,6
        dc.b    174,154,7,141,7,165,7,151,31
        dc.b    $ff
left_speech
        dc.b    31,21,116,23,4,22,55,182,129,194,131,141
        dc.b    2,2,8,186,7,155,4,191,6,145,7,136,7,155,196,6
        dc.b    154,128,6,148,7,137,7,164,18,171,136,191,31
        dc.b    $ff
right_speech
        dc.b    31,21,127,170,128,174,128,170,128,174,128
        dc.b    170,128,174,128,170,128,174,128,170,128,174,128,31
        dc.b    $ff

silence_speech
        dc.b    31
        dc.b    $ff



; Boot Code

boot
        sei
        cld

        ldx     #$ff
        txs

        inx
        txa
boot_loop
        pha
        dex
        bne     boot_loop

        SPEAK   silence_speech


; Display Loop

vertical_sync
        lda     #$02
        sta     WSYNC
        sta     VSYNC

        ldx     #$ff
        txs

        inc     frame

        sta     WSYNC

        lda     #(36*76)>>6
        sta     WSYNC
        sta     TIM64T

        lda     #$00
        sta     WSYNC
        sta     VSYNC


vblank_start
        jsr     read_switches

        jsr     speech_select


        lda     #$03
        sta     WSYNC
        sta     NUSIZ0          ; 3
        sta     NUSIZ1          ; 3 6
        ldx     #$01            ; 2 8
        stx     VDELP0          ; 3 11
        stx     VDELP1          ; 3 14
        stx     CTRLPF          ; 3 17
        dex                     ; 2 19
        stx     GRP0            ; 3 22
        stx     GRP1            ; 3 25
        stx     GRP0            ; 3 28

        lda     #$40            ; 2 30
        sta     HMP0            ; 3 33
        lda     #$50            ; 2 35
        sta     HMP1            ; 3 37

        sta     RESP0           ; 3 40
        sta     RESP1           ; 3 43

        lda     #$04
        sta     COLUBK

        lda     #$28
        sta     COLUP0
        sta     COLUP1

        sta     WSYNC
        sta     HMOVE


        WAIT_TIMINT


display_start
        lda     #$00
        sta     WSYNC
        sta     VBLANK

        lda     #(191*76)>>6
        sta     TIM64T


        WAIT_HBLS       #$40


        lda     #$fe
        sta     WSYNC
        sta     PF2
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC

        ldx     #$10
title_loop
        dex
        sta     WSYNC

        lda     title_sprite0,x         ; 4
        sta     GRP0                    ; 3
        lda     title_sprite1,x         ; 4
        sta     GRP1                    ; 3
        lda     title_sprite2,x         ; 4
        sta     GRP0                    ; 3 21

        ldy     title_sprite3,x         ; 4
        lda     title_sprite4,x         ; 4
        sta     temp                    ; 3
        lda     title_sprite5,x         ; 4 36

        txs                             ; 2
        ldx     temp                    ; 3 41

        sty     GRP1                    ; 3 44
        stx     GRP0                    ; 3 47
        sta     GRP1                    ; 3 50
        sta     GRP0                    ; 3 53

        lda     #$00
        sta     WSYNC
        sta     GRP1
        sta     GRP0
        sta     GRP1

        tsx
        bne     title_loop

        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        lda     #$00
        sta     WSYNC
        sta     PF2


        WAIT_TIMINT


overscan_start
        lda     #$02
        sta     WSYNC
        sta     VBLANK

        lda     #(30*76)>>6
        sta     TIM64T


        SPKOUT  temp


        WAIT_TIMINT

        jmp     vertical_sync



; Subroutines

read_switches
        lda     switch_states
        eor     #$ff
        sta     switch_edges

        lda     SWCHB
        ora     #$f4
        sta     switch_states
        lda     SWCHA
        ora     #$0f
        and     switch_states
        bit     INPT4
        bmi     switches_skip
        and     #$fb
switches_skip
        eor     #$ff
        sta     switch_states
        and     switch_edges
        sta     switch_edges
;        sta COLUBK
        rts



speech_select
        lda     switch_edges
        asl
        bcs     start_rightspeech
        asl
        bcs     start_leftspeech
        asl
        bcs     start_downspeech
        asl
        bcs     start_upspeech
        asl
        bmi     start_firespeech
        rts


    ds 40

start_firespeech
        SPEAK   fire_speech
        rts

start_upspeech
        SPEAK   up_speech
        rts

start_downspeech
        SPEAK   down_speech
        rts

start_leftspeech
        SPEAK   left_speech
        rts


start_rightspeech
        SPEAK   right_speech
        rts


    


; Sprite Data

        align   $100

title_sprite0
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    0
        dc.b    0
        dc.b    %10001000
        dc.b    %10001000
        dc.b    %11111000
        dc.b    %10001000
        dc.b    %10001000
        dc.b    %01010000
        dc.b    %00100011

title_sprite1
        dc.b    %00000010
        dc.b    %00000010
        dc.b    %00000010
        dc.b    %00000010
        dc.b    %00000010
        dc.b    %00000010
        dc.b    %00001111
        dc.b    0
        dc.b    0
        dc.b    %10001000
        dc.b    %10001000
        dc.b    %10001111
        dc.b    %10001000
        dc.b    %10001000
        dc.b    %10000101
        dc.b    %11100010

title_sprite2
        dc.b    %00111110
        dc.b    %00100000
        dc.b    %00100000
        dc.b    %00111100
        dc.b    %00100000
        dc.b    %00100000
        dc.b    %10111110
        dc.b    0
        dc.b    0
        dc.b    %10100010
        dc.b    %10100100
        dc.b    %10101000
        dc.b    %10111100
        dc.b    %10100010
        dc.b    %00100010
        dc.b    %00111100

title_sprite3
        dc.b    %01110000
        dc.b    %10001000
        dc.b    %00001000
        dc.b    %01110000
        dc.b    %10000000
        dc.b    %10001000
        dc.b    %01110011
        dc.b    0
        dc.b    0
        dc.b    %01110000
        dc.b    %00100001
        dc.b    %00100010
        dc.b    %00100010
        dc.b    %00100010
        dc.b    %00100010
        dc.b    %01110010

title_sprite4
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %10000000
        dc.b    %11100000
        dc.b    0
        dc.b    0
        dc.b    %10000111
        dc.b    %01001000
        dc.b    %00101000
        dc.b    %00101000
        dc.b    %00101000
        dc.b    %00101000
        dc.b    %00100111

title_sprite5
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    %00000000
        dc.b    0
        dc.b    0
        dc.b    %00100010
        dc.b    %10100010
        dc.b    %10010100
        dc.b    %10001000
        dc.b    %10010100
        dc.b    %10100010
        dc.b    %00100010




        org     $fffa
        dc.w    boot,boot,boot
