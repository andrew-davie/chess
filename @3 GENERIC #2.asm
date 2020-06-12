; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 3 ; this code assembles for bank #1
    ROMBANK THREE

;---------------------------------------------------------------------------------------------------

    DEF GetPiece
    SUBROUTINE

        REFER aiSelectDestinationSquare ;✅
        REFER aiQuiescent ;✅
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

;         REFER MakeMove ;✅
;         REFER CastleFixupDraw_ENPASSANT ;✅
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

        REFER MakeMove ;✅
        REFER CastleFixupDraw ;✅
        VEND GenCastleMoveForRook

    ; Generate secondary move for the rook, involved in a castling move
    ; Returns:
    ;   CC --> not a castle/secondary
    ;   CS --> secondary move valid


                    clc

                    lda fromPiece
                    and #FLAG_CASTLE
                    beq .exit                       ; NOT involved in castle!

    jsr debug ;tmp
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

    ;     REFER EnPassantCheck
    ;     REFER MakeMove
    ;     VEND GenEnPassantMove


    ;                 rts



;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_3"

;---------------------------------------------------------------------------------------------------
; EOF
