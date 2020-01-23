
            NEWBANK GENERIC_BANK_1

    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

    #if 0
    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF
    #endif


            CHECK_HALF_BANK_SIZE "GENERIC_BANK_1 (DECODE_LEVEL)"

    ;------------------------------------------------------------------------------
    ; ... the above is a RAM-copied section -- the following is ROM-only.  Note that
    ; we do not configure a 1K boundary, as we con't really care when the above 'RAM'
    ; bank finishes.  Just continue on from where it left off...
    ;------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Cart_Init ; in GENERIC_BANK_1

    ; Note the variables from the title selection are incredibly transient an can be stomped
    ; at any time.  So they need to be used immediately.


    ; odd usage below is to prevent any possibility of variable stomping/assumptions

                lda #0
                sta SWBCNT                      ; console I/O always set to INPUT
                sta SWACNT                      ; set controller I/O to INPUT
                sta HMCLR

    ; cleanup remains of title screen
                sta GRP0
                sta GRP1

                lda #%00010000              ; 2     double width missile, double width player
                sta NUSIZ0                  ; 3
                sta NUSIZ1

                lda #%100                       ; players/missiles BEHIND BG
                sta CTRLPF

                lda #$FF
                sta BufferedJoystick

                ;lda #DIRECTION_BITS             ;???
                ;sta ManLastDirection

                ;lda #0
;                sta ObjStackPtr                 ; object stack index of last entry
;                sta ObjStackPtr+1
;                sta ObjStackNum
;                sta ObjIterator

                ;sta sortPtr
                ;lda #<(-1)
                ;sta sortRequired

                rts

    ;-------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE Resync
                RESYNC
Ret             rts

;------------------------------------------------------------------------------


OverscanTime
    .byte OVERSCAN_TIM_NTSC, OVERSCAN_TIM_NTSC
    .byte OVERSCAN_TIM_PAL, OVERSCAN_TIM_NTSC


THROT_BASE = 18
theThrottler
        .byte THROT_BASE, THROT_BASE, THROT_BASE*60/50, THROT_BASE

    DEFINE_SUBROUTINE PostScreenCleanup

                iny                             ; --> 0

                sty COLUBK                      ; starts colour change bottom score area, wraps to top score area
                                                ; + moved here so we don't see a minor colour artefact bottom of screen when look-arounding

                sty PF0                         ; why wasn't this here?  I saw colour glitching in score area!
                                                ; TJ: no idea why, but you had removed it in revision 758 ;)
                                                ; completely accidental -- one of our cats may have deleted it.
                sty PF1
                sty PF2
                sty ENAM0
                sty GRP0                        ; when look-scrolling, we can see feet at the top if these aren't here
                sty GRP1                        ; 30/12/2011 -- fix dots @ top!

    ; D1 VBLANK turns off beam

                lda #%01000010                  ; bit6 is not required
                sta VBLANK                      ; end of screen - enter blanking

    ;------------------------------------------------------------------------------
    ; This is where the PAL system has a bit of extra time on a per-frame basis.

                ldx Platform
                lda OverscanTime,x
                sta TIM64T


    ;----------------------------------------------------------------------------------------------

    ; has to be done AFTER screen display, because it disables the effect!
                ;SLEEP 6
                ;lda rnd                     ; 3     randomly reposition the Cosmic Ark missile
                ;sta HMM0                    ; 3     this assumes that HMOVE is called at least once/frame

noFlashBG
;       sta BGColour

    ; Create a 'standardised' joystick with D4-D7 having bits CLEAR if the appropriate direction is chosen.

                lda SWCHA
                and BufferedJoystick
                sta BufferedJoystick

                rts

;------------------------------------------------------------------------------


            CHECK_BANK_SIZE "GENERIC_BANK_1 -- full 2K"
