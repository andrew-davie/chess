; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 3 ; this code assembles for bank #1
    NEWBANK THREE

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

    DEF GenCastleMoveForRook
    SUBROUTINE

        REFER MakeMove ;✅
        REFER CastleFixupDraw ;✅
        VEND GenCastleMoveForRook

                    clc

                    lda fromPiece
                    and #FLAG_CASTLE
                    beq .exit                       ; NOT involved in castle!

                    ldx #4
                    lda fromX12                     ; *destination*
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


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REFER aiRollPromotionPiece ;✅
        REFER aiChoosePromotePiece ;✅
        VEND showPromoteOptions

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    jsr CopySetupForMarker;@1       ; TODO: WRONG
                    jmp InterceptMarkerCopy;@0


;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "BANK_3"

;---------------------------------------------------------------------------------------------------
; EOF
