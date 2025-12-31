;
; vox_test.asm
;
;
; By Alex Herbert, 2004
;

    SLOT 2
    ROMBANK VOX


; Speakjet Driver



; Constants


SERIAL_OUTMASK  equ     $01
SERIAL_RDYMASK  equ     $02



; Macros

    MACRO SPKOUT


    ; check buffer-full status

                    lda SWCHA
                    and #SERIAL_RDYMASK
                    beq .speech_done

    ; get next speech byte

                    ldy #0
                    lda (speech_addr),y

    ; invert data and check for end of string

                    eor #$ff
                    beq .speech_done
                    sta {1}

    ; increment speech pointer

                    inc speech_addr
                    bne .incaddr_skip
                    inc speech_addr+1
.incaddr_skip

    ; output byte as serial data

                    sec                             ; start bit
.byteout_loop

    ; put carry flag into bit 0 of SWACNT, perserving other bits

                    lda SWACNT                      ; 4
                    and #$fe                        ; 2 6
                    adc #$00                        ; 2 8
                    sta SWACNT                      ; 4 12

    ; 10 bits sent? (1 start bit, 8 data bits, 1 stop bit)

                    cpy     #$09            ; 2 14
                    beq     .speech_done    ; 2 16
                    iny                     ; 2 18

                    SLEEP 36
;                    ; waste some cycles
;                    ldx     #$07
;.delay_loop
;                    dex
;                    bne     .delay_loop     ; 36 54

                    ; shift next data bit into carry
                    lsr     {1}             ; 5 59

                    ; and loop (branch always taken)
                    bpl     .byteout_loop   ; 3 62 cycles for loop

.speech_done

    IF >.byteout_loop != >.
        ECHO "byteout speak page cross"
        ;ERR
    ENDIF

        endm


        mac     SPEAK

        lda     #<{1}
        sta     speech_addr
        lda     #>{1}
        sta     speech_addr+1

        endm







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





; Boot Code

    DEF SayIt

        ;inc     voxframe


        SPKOUT  temp
        rts

; Variables


; Code/Data

;        seg     code
;        org     $f000,$ff


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
        .byte 21, SPKPITCH       ; slower (default=114)
        .byte 20,24  ; volume (default=96)
        .byte 23,4                                  ; band. deep-hollow sound
        dc.b    $ff


SAY_your_move

    ; your = \IY \OWRR
        .byte 128, 153
    ; move= \MM \SLOW \UW \VV
        .byte 140, 8, 139, 166
        .byte $FF


SPKPITCH = 120


;"Ha ha ha"

;"Ha! You have fallen for my trap!"

;"Mate in 236 moves..."

;"I saw that!"

;"Puny human"

;"Don't look a gift knight in the mouth"

;"We all learn from our mistakes: you have infinite improvement capability"

;"You have a good memory for bad openings"

;"You play like a human"

;"You play like a computer"

SAY_blindfold
;"I was playing that one blindfolded"
    .byte 20, 96, 21, 114, 22, 88, 23, 5, 157, 147, 134, 167, 169, 8, 132, 8, 191, 147, 14, 136, 8, 141
    .byte $FF

SAY_atari

    ;"Atari! ..... whoops..... wrong game... Check!"
 .byte 20, 96, 21, 114, 22, 88, 23, 5, 148, 136, 8, 144, 8, 178, 154, 140, 182, 131, 131, 196
 .byte $FF

SAY_feet

;"If i had feet, I'd be kicking you under the table right now"
 .byte 20, 96, 21, 114, 22, 88, 23, 5, 129, 186, 186, 157, 186, 128, 191, 2, 8, 160, 134, 141, 175, 151, 8, 169, 8, 128, 191, 7, 130, 7, 154, 18, 170, 7, 134, 146, 148, 7, 155, 7, 128, 191, 142, 163
 .byte $FF

SAY_mistake

    ;"I know you would make that mistake"
 .byte 20, 96, 21, 114, 22, 88, 23, 5, 157, 8, 160, 147, 8, 138, 177, 140, 154, 196, 169, 8, 132, 8, 191, 140, 7, 129, 187, 191, 154, 196
 .byte $FF



SAY_noCPU
    ;"Without a CPU i would try that move too"

    ;with= \WW \IH \SLOW \SLOW \TH
    .byte 21,120
    .byte 147, 129, 8, 8, 190
    ;out = \AYWW \TT
    .byte 163, 191
    .byte 21, SPKPITCH
    
    ; a = \UX (mine)
        .byte 9, 134

    ; CPU
    .byte 187, 8, 128
    .byte 0
    .byte 198, 8,128
    .byte 0
    .byte 8, 160

    .byte 2


 .byte 20, 96, 21, 114, 22, 88, 23, 5, 157, 147, 8, 138, 177, 8, 191, 7, 148, 155, 169, 8, 132, 8, 191, 140, 8, 139, 166, 8, 191, 162
 .byte $FF


;And I'm going to have the computer call the piece a "horsie" instead of a knight

SAY_how_about
SAY_NQB3

    ; horse= \HO \OWRR \SE \IY
    .byte 20, 96, 21, 114, 22, 88, 23, 5
; horsie
 ;.byte 8, 191, 162
 .byte 0

; queens
; .byte 20, 96, 21, 114, 22, 88, 23, 5
; .byte 0

; bishop
; .byte 20, 96, 21, 114, 22, 88, 23, 5
; .byte 0


; three
; .byte 20, 96, 21, 114, 22, 88, 23, 5, 8, 190, 148, 8, 128
 .byte $FF




;SAY_how_about

; .byte 20, 96, 21, 114, 22, 88, 23, 5, 141, 136, 191, 154, 128, 166, 150, 7, 128, 8, 179, 138, 138, 177, 140, 8, 139, 166
; .byte $FF

    ; how about a nice game of chess

    ;how= \HO \SLOW \AYWW

    ;.byte 21,120
        ;.byte 184, 8, 163

    .byte 0

    ;about=\UX \OB \AYWW \TT  

;        .byte 134, 8, 173, 163, 191


    .byte 9,
    ;.byte 134 ;\UX
    ;.byte 21,64
    .byte 8,173 ;\OB
    ;.byte 21,SPKPITCH
    .byte 163 ;\AYWW
    .byte 14
    .byte 8, 191 ;\TT
    .byte $FF



    .byte 21, SPKPITCH
    ; a = \UX (mine)
        .byte 9, 134


    ;nine =\NE \Stress \OHIH \NE     

        .byte 141, 14, 157, 188

    ;game =\Slow \GE \EYIY \MM 

        .byte 8, 178, 154, 8,140
        .byte 0


    ;of = \SLOW \UX \VV
        .byte 8, 134, 166

    ;chess\CH \EH \EH \SE 
        .byte 182, 131, 131, 8, 187
        .byte $FF



SAY_hi_mum

        ;.byte 21, SPKPITCH       ; slower (default=114)

    ; say= \SE \FAST \EY \EYIY

        .byte 187, 9, 130, 154
        .byte 4

    ; hi= \HO \SLOW \OHIY
        .byte 20,32
        .byte 14, 184, 8, 14, 155
        .byte 4
        .byte 20,24        

    ; to = \SLOW \TT \SLOW \IHWW
        .byte 8, 191, 8, 162
        ;.byte 4

    ; your = \IY \SLOW \OWRR
        .byte 191, 8, 128, 153

    ; much= \MM \SLOW \UX \MM
        .byte 8, 140, 8, 136
        .byte 21, 80
        .byte 140


        .byte 21, 120

    ; for = \FF \SLOW \OWRR \SLOW \OWRR
        .byte 186, 8, 153
        .byte 20,16
        .byte 148
        .byte 20,24
        .byte 21, SPKPITCH

    ; me = \MM \IY \SLOW \IY
        .byte 140, 128, 8, 128, 128

    .byte $FF

SAY_you_are_a_loser

    ; you = \SLOW \IYUW
        .byte 8, 160

    ; are= \AWRR
        .byte 152

    ; a = \UX (mine)
        .byte 9, 134

    ; lose= \LO \SLOW \UW \FAST \ZZ (R=\SLOW \RR 148)
        .byte 146, 8, 160, 8, 168, 8, 151

    .byte $FF

SAY_computer_moved

    ; your = \IY \OWRR
        .byte 128, 153
    ; mistake= \MM \FAST \IH \SE \TT \EYIY \EK
        .byte 140, 7, 129, 8, 187, 191, 154, 196

    .byte 2 ;delay

    ; you = \SLOW \IYUW
        .byte 8, 160
    ; suck = \SLOW \SE \SLOW \UX \EK
        .byte 8, 192, 8, 134, 196
    .byte $FF





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





    END_BANK