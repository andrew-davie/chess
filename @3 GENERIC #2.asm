;---------------------------------------------------------------------------------------------------
; @3 GENERIC #2.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 3
    ROMBANK THREE

    DEF Breaker
                    brk


;---------------------------------------------------------------------------------------------------

    DEF GetPiece
    SUBROUTINE

        REF aiSelectDestinationSquare ;✅
        REF aiQuiescent ;✅
        VEND GetPiece

    ; Retrieve the piece+flags from the movelist, given from/to squares
    ; Required as moves have different flags but same origin squares (e.g., castling)

                    lda #RAMBANK_PLY+1 ;currentPly
                    ;lda currentPly
                    sta SET_BANK_RAM;@2

    ; returns piece in A+fromPiece
    ; or Y=-1 if not found

    ; We need to get the piece from the movelist because it contains flags (e.g., castling) about
    ; the move. We need to do from/to checks because moves can have multiple origin/desinations.
    ; This fixes the move with/without castle flag


                    ldy@PLY moveIndex
                    bmi .fail                       ; shouldn't happen

.scan               lda fromX12
                    cmp@PLY MoveFrom,y
                    bne .next
                    lda toX12                    
                    cmp@PLY MoveTo,y
                    beq .found
.next               dey
                    bpl .scan
.fail               rts

.found              lda@PLY MovePiece,y
                    sta fromPiece

                    rts


;---------------------------------------------------------------------------------------------------

    DEF GenCastleMoveForRook
    SUBROUTINE

        REF MakeMove ;✅
        REF CastleFixupDraw ;✅
        VEND GenCastleMoveForRook

    ; Generate secondary move for the rook, involved in a castling move
    ; Returns:
    ;   CC --> not a castle/secondary
    ;   CS --> secondary move valid


                    clc

                    lda fromPiece
                    and #FLAG_CASTLE
                    beq .exit                       ; NOT involved in castle!

                    ldx #4
                    lda toX12                     ; *destination*
.findCast           clc
                    dex
                    bmi .exit
                    cmp KSquare,x
                    bne .findCast

                    lda RSquareEnd,x
                    sta toX12
                    sta@PLY secondaryBlank
                    ldy RSquareStart,x
                    sty fromX12
                    sty originX12
                    sty@PLY secondarySquare

                    lda fromPiece
                    and #128                        ; colour bit
                    ora #ROOK                       ; preserve colour
                    sta fromPiece
                    sta __originalPiece
                    sta@PLY secondaryPiece

                    sec
.exit               rts


KSquare             .byte 24,28,94,98
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97
virtualSquare1      .byte 25,27,95,97
;virtualSquare2      .byte 26,26,96,96

;---------------------------------------------------------------------------------------------------

    ; DEF GenEnPassantMove
    ; SUBROUTINE

    ;     REF EnPassantCheck
    ;     REF MakeMove
    ;     VEND GenEnPassantMove


    ;                 rts



    ; The reset vectors
    ; these must live in the fixed bank (bank 0 in 3E+ format)

;    ORG $63FC
;    RORG $FFFC

;                    .word StartCartridge            ; RESET
;                    .word StartCartridge            ; IRQ        (not used)


;---------------------------------------------------------------------------------------------------

    DEF InterlaceFrame


    ; START OF FRAME


    IF 0

                    lda SWCHB
                    bmi .normal                     ; RIGHT difficulty switches on/off

                    dec framenum
                    lda framenum
                    lsr
                    bcs .normal

                    SLEEP 36

.normal             lda #2
                    sta WSYNC
                    sta VSYNC

	                sta WSYNC                       ; line 1 of VSYNC
	                sta WSYNC                       ; line 2 of VSYNC

                	lda	#0
	                sta WSYNC                       ; line 3 of VSYNC
	                sta VSYNC                       ; @0


                    sta VBLANK

    ENDIF



    IF 1


frame
;Vertical sync
	;dec	framenum
	
	;lda	interlaced		;see if we are in interlaced mode
	;beq	non_interlaced	

    lda SWCHB
    bmi even_sync

    dec framenum
	lda framenum
    and #1
	beq	even_sync	

non_interlaced			;entry point for non-interlaced
	;this is the vertical sync for the first field of an interlaced frame
	;or just a normal non-interlaced vertical sync
	lda #2
	sta WSYNC
	sta VSYNC ; Begin vertical sync.

	sta WSYNC ; First line of VSYNC
	sta WSYNC ; Second line of VSYNC.
	lda	#0
	sta WSYNC ; Third line of VSYNC.
	sta VSYNC ; (0)

	jmp done_sync
even_sync
	;this is the vertical sync for the second field of an interlaced fram
	sta WSYNC
	;need 40 cycles until the start of vertical sync
	
    SLEEP 36


	lda #2		;40
		
	sta VSYNC ; Begin vertical sync.
	sta WSYNC ; First line of VSYNC
	sta WSYNC ; Second line of VSYNC.

	sta WSYNC ; Third line of VSYNC.
	;need 33 cycles until the end of VSYNC


    ;SLEEP 10



	lda #0	;33
	sta VSYNC 

done_sync

;	LDA #40		;timer for 34 lines of blanking
;	STA TIM64T
        ENDIF


;                    lda #%1110                      ; VSYNC ON
;.loopVSync3         sta WSYNC
;                    sta VSYNC
;                    lsr
;                    bne .loopVSync3                 ; branch until VYSNC has been reset

;                    sta VBLANK

                    rts


;---------------------------------------------------------------------------------------------------

    DEF BubbleSort
    SUBROUTINE


    IF 1
    ;{

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty
    ; x must be preserved

    ; note that 'alpha' and 'beta' are set externally!!

                    lda #-1
                    sta@PLY bestMove

                    lda enPassantPawn               ; flag/square from last actual move made
                    sta@PLY enPassantSquare         ; used for backtracking, to reset the flag

                    lda vkSquare
                    sta@PLY virtualKingSquare
                    lda vkSquare+1
                    sta@PLY virtualKingSquare+1     ; traversal squares of king for castling

    ; The value of the material (signed, 16-bit) is restored to the saved value at the reversion
    ; of a move. It's quicker to restore than to re-sum. So we save the current evaluation at the
    ; start of each new ply.

                    lda Evaluation
                    sta@PLY savedEvaluation
                    lda Evaluation+1
                    sta@PLY savedEvaluation+1
    ;}
    ENDIF


                    clc
                    lda currentPly
                    adc #RAMBANK_SORT-RAMBANK_PLY
                    sta __bank2


                    lda@PLY moveIndex
                    bpl .start                      ; no moves - no sorting
                    rts
                    
.start

                    sta __n
                    inc __n                         ; n := length(A)

.bubble             lda #0
                    sta __newn

                    lda #1
                    sta __i

.bubbleLoop         lda __i
                    cmp __n
                    beq .exitBubble

                    tax                             ; A
                    tay
                    dey                             ; B i-1

                    lda __bank2
                    sta SET_BANK_RAM;@2

                    sec
                    lda MoveValueLO,x
                    sbc MoveValueLO,y
                    lda MoveValueHI,x
                    sbc MoveValueHI,y
                    bvc .cmp16bit
                    eor #$80
.cmp16bit           bmi .lessThan                   ; sort small to large

    ; swap!
                    XCHG MoveValueLO
                    XCHG MoveValueHI

                    lda currentPly
                    sta SET_BANK_RAM;@2

                    XCHG MoveFrom
                    XCHG MoveTo
                    XCHG MovePiece
                    XCHG MoveCapture

                    lda __i
                    sta __newn

.lessThan           inc __i
                    jmp .bubbleLoop

.exitBubble         lda __newn
                    sta __n

                    cmp #2
                    bcc .exitLoop
                    jmp .bubble

.exitLoop           lda currentPly
                    sta SET_BANK_RAM

                    rts


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
; EOF
