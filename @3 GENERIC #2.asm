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

;     DEF GenCastleMoveForRook_ENPASSANT
;     SUBROUTINE

;         REF MakeMove ;✅
;         REF CastleFixupDraw_ENPASSANT ;✅
;         VEND GenCastleMoveForRook_ENPASSANT

;         rts ;tmp
;         jsr debug ;tmp

;     ; Like castling, this generates the acutal extra-move for the en-passant


;     ; Check to see if we are doing an actual en-passant capture...

;     ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
;     ;  as the en-passant will fail if the taking piece does not have this flag set correctly



;     ; {
;     ; With en-passant flag, it is essentially dual-use.
;     ; First, it marks if the move is *involved* somehow in an en-passant
;     ; if the piece has MOVED already, then it's an en-passant capture
;     ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

;                     ldy enPassantPawn               ; save from previous side move

;                     ldx #0                          ; (probably) NO en-passant this time
;                     lda fromPiece
;                     and #FLAG_ENPASSANT|FLAG_MOVED
;                     cmp #FLAG_ENPASSANT
;                     bne .noep                       ; HAS moved, or not en-passant

;                     eor fromPiece                   ; clear FLAG_ENPASSANT
;                     sta fromPiece

;                     ldx toX12                       ; this IS an en-passantable opening, so record the square
; .noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

;     ; }

;                     clc

;                     lda fromPiece
;                     and #FLAG_ENPASSANT
;                     beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece


;     ; at this point the attacking pawn has finished moving to the "take" square
;     ; the loser-pawn is marked with enPassantPawn
;     ; we want to generate a 'blank' move to take the pawn

;                     lda originX12                   ; we need a blank square to move FROM
;                     sta fromX12                     ; use the square the attacker pawn just left

;     ; calculate the captured pawn's square based on move colour

;                     lda #-10
;                     ldx fromPiece
;                     bpl .white
;                     lda #10
; .white
;                     clc
;                     adc fromX12                     ; attacker destination square
;                     sta toX12                       ; now we have the captured pawn square!
;                     sta@PLY secondarySquare         ; square to which we RESTORE the captured pawn on unmakemove

;                     sta@PLY secondaryBlank
;                     lda fromPiece
;                     eor #$80                        ; opponent pawn
;                     sta@PLY secondaryPiece          ; a capture!


;                     sec                             ; double-move, so don't change sides
; .notEnPassant       rts


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

    END_BANK

;---------------------------------------------------------------------------------------------------
; EOF
