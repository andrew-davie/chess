    NEWBANK SPEAK

;
; speakjet.inc
;
;
; AtariVox Speech Synth Driver
;
; By Alex Herbert, 2004
;




; Constants


SERIAL_OUTMASK  equ     $01
SERIAL_RDYMASK  equ     $02



;---------------------------------------------------------------------------------------------------

        mac     SPEAK

        lda     #<{1}
        sta     speech_addr
        lda     #>{1}
        sta     speech_addr+1

        endm


;---------------------------------------------------------------------------------------------------

    DEF ShutYourMouth
    SUBROUTINE

        REFER Reset
        VEND ShutYourMouth

                    SPEAK silence_speech
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GameSpeak
    SUBROUTINE

        REFER Reset
        VAR __speak_temp, 1
        VEND GameSpeak

                    ldy #0
                    lda (speech_addr),y
                    cmp #$ff
                    bne .talk

                    SPEAK left_speech


.talk 

    ; check buffer-full status

                    lda SWCHA
                    and #SERIAL_RDYMASK
                    beq .speech_done

                    ldy #0
                    lda (speech_addr),y

                    eor #$ff
                    beq .speech_done
                    sta __speak_temp

                    inc speech_addr
                    bne .incaddr_skip
                    inc speech_addr+1
.incaddr_skip

                    sec                 ; start bit
.byteout_loop

    ; put carry flag into bit 0 of SWACNT, perserving other bits
 
                    lda SWACNT          ; 4
                    and #$fe            ; 2 6
                    adc #$00            ; 2 8
                    sta SWACNT          ; 4 12

    ; 10 bits sent? (1 start bit, 8 data bits, 1 stop bit)

                    cpy #$09            ; 2 14
                    beq .speech_done    ; 2 16
                    iny                 ; 2 18


                    ldx #$07            ; 2 20
.delay_loop         dex                 ; { 2
                    bne .delay_loop     ;   3
                                        ; } = 7 * 5 - 1 = 34
                                        ; @54

                    lsr __speak_temp            ; 5 59
                    bpl .byteout_loop   ; 3 62 cycles for loop

.speech_done        rts


;---------------------------------------------------------------------------------------------------

; Speech Data

;Dec. SpeakJet Use
;----- ------------------
;000 Pause 0
;001 Pause 1
;002 Pause 2
;003 Pause 3
;004 Pause 4
;005 Pause 5
;006 Pause 6
;007 Play Next Sound Fast
;008 Play Next Sound Slow
;014 Play Next Sound High Tone
;015 Play Next Sound Low Tone
;016 Wait
;020 Volume, X
;021 Speed, X
;022 Pitch, X
;023 Bend, X
;024 PortCtr, X
;025 Port, X
;026 Repeat, X
;028 Call Phrase, X
;029 Goto Phrase, X
;030 Delay, X
;031 Reset Defaults
;--------------------------------------------------------
;032 Reserved
;- to -
;127
;--------------------------------------------------------
;128 127 Sound codes
;- to -
;254
;--------------------------------------------------------
;255 End of Phrase.



left_speech


        dc.b    31
;        dc.b $ff




        
        
        
        dc.b    21,116          ; speed 116
        dc.b    23,4            ; bend, 4
        dc.b    22,55           ; pitch, 55
        dc.b    182 ;CH
        dc.b    129 ;IH
        dc.b    194 ;KE
        dc.b    131 ;EH
        dc.b    141 ;NE
        dc.b    2               ; pause 2
        dc.b    2               ; pause 2


        dc.b    8               ; play next sound slow
        dc.b    186 ;FF
        dc.b    7               ; play fast
        dc.b    155 ;OHIY
        dc.b    4               ; pause 4
        dc.b    191 ;TT
        dc.b    6               ; pause 6
        dc.b    145 ;LE
        dc.b    7               ; fast
        dc.b    136 ;AW
        dc.b    7               ; fast
        dc.b    155 ;OHIY
        dc.b    196 ;EK
        dc.b    6               ; pause 6
        dc.b    154 ;EYIY
        dc.b    128 ;IY
        dc.b    6               ; pause 6
        dc.b    148 ;GR?
        dc.b    7               ; fast
        dc.b    137 ;OW
        dc.b    7               ; fast
        dc.b    164 ;OWW
        dc.b    18              ;???
        dc.b    171 ;BO
        dc.b    136 ;AW
        dc.b    191 ;TT
        dc.b    31              ; reset defaults
        dc.b    $ff


silence_speech



        dc.b    31 ;31


        dc.b    $ff

    CHECK_BANK_SIZE "BANK_SPEAK"

#if 0
typedef enum
  182     
  183         Pause0        = 0,                     ///< Pause 0ms
  184         Pause1        = 1,                     ///< Pause 100ms
  185         Pause2        = 2,                     ///< Pause 200ms
  186         Pause3        = 3,                     ///< Pause 700ms
  187         Pause4        = 4,                     ///< Pause 30ms
  188         Pause5        = 5,                     ///< Pause 60ms
  189         Pause6        = 6,                     ///< Pause 90ms
  190         Fast          = 7,                     ///< Next phoneme at 0.5 speed
  191         Slow          = 8,                     ///< Next phoneme at 1.5 speed
  192         Stress        = 14,                    ///< Next phoneme with some stress
  193         Relax         = 15,                    ///< Next phoneme with relaxation
  194         Wait          = 16,                    ///< Stops and waits for a Start (see manual)
  195         Soft          = 18,                    ///< Stops and waits for a Start (see manual)
  196         Volume        = 20,                    ///< Next octet is volume 0 to 127. Default 96
  197         Speed         = 21,                    ///< Next octet is speed 0 to 127. Default 114
  198         Pitch         = 22,                    ///< Next octet is pitch in Hz = to 255
  199         Bend          = 23,                    ///< Next octet is frequency bend  to 15. Default is 5
  200         PortCtr       = 24,                    ///< Next octet is port control value. See manual. Default is 7
  201         Port          = 25,                    ///< Next octet is Port Output Value. See manual. Default is 0
  202         Repeat        = 26,                    ///< Next octet is repeat count. 0 to 255
  203         CallPhrase    = 28,                    ///< Next octet is EEPROM phrase to play and return. See manual.
  204         GotoPhrase    = 29,                    ///< Next octet is EEPROM phgrase to go to. See manual.
  205         Delay         = 30,                    ///< Next octet is delay in multiples of 10ms. 0 to 255.
  206         Reset         = 31,                    ///< Reset Volume Speed, Pitch, Bend to defaults.
  207 
  208         // 32 to 127 reserved
  209 
  210         // 128 to 254 Sound codes
  211         // Phonemes, standard names
  212         Phoneme_IY    = 128,                   ///< 70ms Voiced Long Vowel
  213         Phoneme_IH    = 129,                   ///< 70ms Voiced Long Vowel
  214         Phoneme_EY    = 130,                   ///< 70ms Voiced Long Vowel
  215         Phoneme_EH    = 131,                   ///< 70ms Voiced Long Vowel
  216         Phoneme_AY    = 132,                   ///< 70ms Voiced Long Vowel
  217         Phoneme_AX    = 133,                   ///< 70ms Voiced Long Vowel
  218         Phoneme_UX    = 134,                   ///< 70ms Voiced Long Vowel
  219         Phoneme_OH    = 135,                   ///< 70ms Voiced Long Vowel
  220         Phoneme_AW    = 136,                   ///< 70ms Voiced Long Vowel
  221         Phoneme_OW    = 137,                   ///< 70ms Voiced Long Vowel
  222         Phoneme_UH    = 138,                   ///< 70ms Voiced Long Vowel
  223         Phoneme_UW    = 139,                   ///< 70ms Voiced Long Vowel
  224         Phoneme_MM    = 140,                   ///< 70ms Voiced Nasal
  225         Phoneme_NE    = 141,                   ///< 70ms Voiced Nasal
  226         Phoneme_NO    = 142,                   ///< 70ms Voiced Nasal
  227         Phoneme_NGE   = 143,                   ///< 70ms Voiced Nasal
  228         Phoneme_NGO   = 144,                   ///< 70ms Voiced Nasal
  229         Phoneme_LE    = 145,                   ///< 70ms Voiced Resonate
  230         Phoneme_LO    = 146,                   ///< 70ms Voiced Resonate
  231         Phoneme_WW    = 147,                   ///< 70ms Voiced Resonate
  232         Phoneme_RR    = 149,  //148?                   ///< 70ms Voiced Resonate
  233         Phoneme_IYRR  = 149,                   ///< 200ms Voiced R Color Vowel
  234         Phoneme_EYRR  = 150,                   ///< 200ms Voiced R Color Vowel
  235         Phoneme_AXRR  = 151,                   ///< 190ms Voiced R Color Vowel
  236         Phoneme_AWRR  = 152,                   ///< 200ms Voiced R Color Vowel
  237         Phoneme_OWRR  = 153,                   ///< 185ms Voiced R Color Vowel
  238         Phoneme_EYIY  = 154,                   ///< 165ms Voiced Diphthong
  239         Phoneme_OHIY  = 155,                   ///< 200ms Voiced Diphthong
  240         Phoneme_OWIY  = 156,                   ///< 225ms Voiced Diphthong
  241         Phoneme_OHIH  = 157,                   ///< 185ms Voiced Diphthong
  242         Phoneme_IYEH  = 158,                   ///< 170ms Voiced Diphthong
  243         Phoneme_EHLE  = 159,                   ///< 140ms Voiced Diphthong
  244         Phoneme_IYUW  = 160,                   ///< 180ms Voiced Diphthong
  245         Phoneme_AXUW  = 161,                   ///< 170ms Voiced Diphthong
  246         Phoneme_IHWW  = 162,                   ///< 170ms Voiced Diphthong
  247         Phoneme_AYWW  = 163,                   ///< 200ms Voiced Diphthong
  248         Phoneme_OWWW  = 164,                   ///< 131ms Voiced Diphthong
  249         Phoneme_JH    = 165,                   ///< 70ms Voiced Affricate
  250         Phoneme_VV    = 166,                   ///< 70ms Voiced Fricative
  251         Phoneme_ZZ    = 167,                   ///< 70ms Voiced Fricative 
  252         Phoneme_ZH    = 168,                   ///< 70ms Voiced Fricative
  253         Phoneme_DH    = 169,                   ///< 70ms Voiced Fricative
  254         Phoneme_BE    = 170,                   ///< 45ms Voiced Stop
  255         Phoneme_BO    = 171,                   ///< 45ms Voiced Stop
  256         Phoneme_EB    = 172,                   ///< 10ms Voiced Stop
  257         Phoneme_OB    = 173,                   ///< 10ms Voiced Stop
  258         Phoneme_DE    = 174,                   ///< 45ms Voiced Stop
  259         Phoneme_DO    = 174,                   ///< 45ms Voiced Stop
  260         Phoneme_ED    = 176,                   ///< 10ms Voiced Stop
  261         Phoneme_OD    = 177,                   ///< 10ms Voiced Stop
  262         Phoneme_GE    = 178,                   ///< 55ms Voiced Stop
  263         Phoneme_GO    = 179,                   ///< 55ms Voiced Stop
  264         Phoneme_EG    = 180,                   ///< 55ms Voiced Stop
  265         Phoneme_OG    = 181,                   ///< 55ms Voiced Stop
  266         Phoneme_CH    = 182,                   ///< 70ms Voiceless Affricate
  267         Phoneme_HE    = 183,                   ///< 70ms Voiceless Fricative
  268         Phoneme_HO    = 184,                   ///< 70ms Voiceless Fricative
  269         Phoneme_WH    = 185,                   ///< 70ms Voiceless Fricative
  270         Phoneme_FF    = 186,                   ///< 70ms Voiceless Fricative
  271         Phoneme_SE    = 187,                   ///< 40ms Voiceless Fricative
  272         Phoneme_SO    = 188,                   ///< 40ms Voiceless Fricative
  273         Phoneme_SH    = 189,                   ///< 50ms Voiceless Fricative
  274         Phoneme_TH    = 190,                   ///< 40ms Voiceless Fricative
  275         Phoneme_TT    = 191,                   ///< 50ms Voiceless Stop
  276         Phoneme_TU    = 192,                   ///< 70ms Voiceless Stop
  277         Phoneme_TS    = 193,                   ///< 170ms Voiceless Stop
  278         Phoneme_KE    = 194,                   ///< 55ms Voiceless Stop
  279         Phoneme_KO    = 195,                   ///< 55ms Voiceless Stop
  280         Phoneme_EK    = 196,                   ///< 55ms Voiceless Stop
  281         Phoneme_OK    = 197,                   ///< 45ms Voiceless Stop
  282         Phoneme_PE    = 198,                   ///< 99ms Voiceless Stop
  283         Phoneme_PO    = 199,                   ///< 99ms Voiceless Stop
  284         // Robot sound
  285         Sound_R0      = 200,                   ///< 80ms Robot
  286         Sound_R1      = 201,                   ///< 80ms Robot
  287         Sound_R2      = 202,                   ///< 80ms Robot
  288         Sound_R3      = 203,                   ///< 80ms Robot
  289         Sound_R4      = 204,                   ///< 80ms Robot
  290         Sound_R5      = 205,                   ///< 80ms Robot
  291         Sound_R6      = 206,                   ///< 80ms Robot
  292         Sound_R7      = 207,                   ///< 80ms Robot
  293         Sound_R8      = 208,                   ///< 80ms Robot
  294         Sound_R9      = 209,                   ///< 80ms Robot
  295         // Alarm sound
  296         Sound_A0      = 210,                   ///< 300ms Alarm
  297         Sound_A1      = 211,                   ///< 101ms Alarm
  298         Sound_A2      = 212,                   ///< 102ms Alarm
  299         Sound_A3      = 213,                   ///< 540ms Alarm
  300         Sound_A4      = 214,                   ///< 530ms Alarm
  301         Sound_A5      = 215,                   ///< 500ms Alarm
  302         Sound_A6      = 216,                   ///< 135ms Alarm
  303         Sound_A7      = 217,                   ///< 600ms Alarm
  304         Sound_A8      = 218,                   ///< 300ms Alarm
  305         Sound_A9      = 219,                   ///< 250ms Alarm
  306         // Beeps
  307         Sound_B0      = 220,                   ///< 200ms Beep
  308         Sound_B1      = 221,                   ///< 270ms Beep
  309         Sound_B2      = 222,                   ///< 280ms Beep
  310         Sound_B3      = 223,                   ///< 260ms Beep
  311         Sound_B4      = 224,                   ///< 300ms Beep
  312         Sound_B5      = 225,                   ///< 100ms Beep
  313         Sound_B6      = 226,                   ///< 104ms Beep
  314         Sound_B7      = 227,                   ///< 100ms Beep
  315         Sound_B8      = 228,                   ///< 270ms Beep
  316         Sound_B9      = 229,                   ///< 262ms Beep
  317         // Biological
  318         Sound_C0      = 230,                   ///< 160ms Biological
  319         Sound_C1      = 231,                   ///< 300ms Biological
  320         Sound_C2      = 232,                   ///< 182ms Biological
  321         Sound_C3      = 233,                   ///< 120ms Biological
  322         Sound_C4      = 234,                   ///< 175ms Biological
  323         Sound_C5      = 235,                   ///< 350ms Biological
  324         Sound_C6      = 236,                   ///< 160ms Biological
  325         Sound_C7      = 237,                   ///< 260ms Biological
  326         Sound_C8      = 238,                   ///< 95ms Biological
  327         Sound_C9      = 239,                   ///< 75ms Biological
  328         // DTMF 
  329         DTMF_0        = 240,                   ///< DTMF 0 95ms
  330         DTMF_1        = 241,                   ///< DTMF 1 95ms
  331         DTMF_2        = 242,                   ///< DTMF 2 95ms
  332         DTMF_3        = 243,                   ///< DTMF 3 95ms
  333         DTMF_4        = 244,                   ///< DTMF 4 95ms
  334         DTMF_5        = 245,                   ///< DTMF 5 95ms
  335         DTMF_6        = 246,                   ///< DTMF 6 95ms
  336         DTMF_7        = 247,                   ///< DTMF 7 95ms
  337         DTMF_8        = 248,                   ///< DTMF 8 95ms
  338         DTMF_9        = 249,                   ///< DTMF 9 95ms
  339         DTMF_STAR     = 250,                   ///< DTMF * 95ms
  340         DTMF_HASH     = 251,                   ///< DTMF # 95ms
  341         // Miscellaneous
  342         Sound_M0      = 252,                   ///< Sonar ping 125ms
  343         Sound_M1      = 253,                   ///< Pistol shot 250ms
  344         Sound_M2      = 254,                   ///< WOW 530ms
  345 
  346         EndOfPhrase   = 255,                   ///< End of phrase marker. Required at end of code arrays
  347 
  348      CommandCodes;
  349 
  #endif
