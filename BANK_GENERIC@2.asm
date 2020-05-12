
            SLOT 2
            NEWBANK GENERIC_BANK@2

;    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

    IF 0
    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF
    ENDIF

;STELLA_AUTODETECT .byte $85,$3e,$a9,$00 ; 3E




;---------------------------------------------------------------------------------------------------

    DEF tidySc
    SUBROUTINE

        REFER StartupBankReset
        VEND tidySc

                    lda #0
                    sta PF0
                    sta PF1
                    sta PF2
                    sta GRP0
                    sta GRP1

                    lda #%01000010                  ; bit6 is not required
                    ;sta VBLANK                      ; end of screen - enter blanking


; END OF VISIBLE SCREEN
; HERE'S SOME TIME TO DO STUFF

                    lda #TIME_PART_2
                    sta TIM64T
                    rts


;---------------------------------------------------------------------------------------------------

    DEF longD
    SUBROUTINE

                    sta WSYNC

                    jsr _rts
                    jsr _rts
                    jsr _rts
                    SLEEP 7

                    ldx #0
                    stx VBLANK
_rts                rts

    IF 0
    DEF Resync
    SUBROUTINE

                    RESYNC
                    rts
    ENDIF


;---------------------------------------------------------------------------------------------------

    DEF aiStartClearBoard
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStartClearBoard

                    ldx #8
                    stx drawCount                   ; = bank

                    lda #-1
                    sta cursorX12

                    PHASE AI_ClearEachRow
                    rts

;---------------------------------------------------------------------------------------------------

    DEF aiClearEachRow
    SUBROUTINE

        REFER AiStateMachine
        VEND aiClearEachRow

                    dec drawCount
                    bmi .bitmapCleared
                    ;TODOldy drawCount
                    ;TODO jmp CallClear

.bitmapCleared

                    lda #99
                    sta squareToDraw

                    PHASE AI_DrawEntireBoard
                    rts



;---------------------------------------------------------------------------------------------------

    DEF aiMoveIsSelected
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMoveIsSelected

    ; Both computer and human have now seleted a move, and converge here


    ; fromPiece     piece doing the move
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12

                    jsr AdjustMaterialPositionalValue;@this

                    lda #0
                    sta previousPiece
                    sta drawDelay

                    lda #10                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move

                    PHASE AI_WriteStartPieceBlank
.idleErase          rts


;---------------------------------------------------------------------------------------------------

    DEF CopySetup
    SUBROUTINE

        REFER CopySinglePiece

        VAR __tmp, 1
        VAR __shiftx, 1
        VAR __pieceColour2, 1

        VEND CopySetup

    ; figure colouration of square

                    lda squareToDraw

    IF DIAGNOSTICS
    ; Catch out-of-range piece square
    ; will not catch off left/right edge

.fail               cmp #100
                    bcs .fail
                    cmp #22
                    bcc .fail
    ENDIF


                    ldx #10
                    sec
.sub10              sbc #10
                    dex
                    bcs .sub10
                    adc #8
                    sta __shiftx
    IF DIAGNOSTICS
.fail2              cmp #8
                    bcs .fail2
                    cpx #8
                    bcs .fail2
    ENDIF
                    stx __tmp                    
                    adc __tmp


                    and #1
                    eor #1
                    beq .white
                    lda #36
.white
                    sta __pieceColour2              ; actually SQUARE black/white

    ; PieceColour = 0 for white square, 36 for black square

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3

                    ldy squareToDraw
                    lda Board,y
                    ;and #$87
                    asl
                    bcc .blackAdjust
                    ora #16                         ; switch white pieces
.blackAdjust        lsr
                    and #%1111
                    tax

                    lda __shiftx
                    and #3                          ; shift position in P

                    clc
                    adc PieceToShape,x
                    clc
                    adc __pieceColour2
                    tay
                    rts

PieceToShape

    .byte INDEX_WHITE_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0                ; impossible (black P)
    .byte INDEX_WHITE_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_WHITE_KING_on_WHITE_SQUARE_0

    .byte INDEX_BLACK_BLANK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0                ; impossible (white P)
    .byte INDEX_BLACK_PAWN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KNIGHT_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_BISHOP_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_ROOK_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_QUEEN_on_WHITE_SQUARE_0
    .byte INDEX_BLACK_KING_on_WHITE_SQUARE_0


;---------------------------------------------------------------------------------------------------

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.

    ; First, nominate referencing subroutines so that local variables can be adjusted properly

        REFER MakeMove
        REFER aiMoveIsSelected

        VAR __originalPiece, 1
        VAR __capturedPiece, 1
        
        VEND AdjustMaterialPositionalValue

    ; fromPiece     piece doing the move (promoted type)
    ; fromX12       current square
    ; originX12     starting square
    ; toX12         ending square


    ; get the piece types from the board

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    ldy originX12
                    lda Board,y
                    sta __originalPiece
                    ldy toX12
                    lda Board,y
                    sta __capturedPiece

    ; {
    ;   adjust the positional value  (originX12 --> fromX12)

                    lda #RAMBANK_BANK_EVAL
                    sta SET_BANK_RAM;@3


                    ;ldy toX12                      ; already loaded
                    lda fromPiece
                    jsr AddPiecePositionValue       ; add pos value for new position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same1                      ; unchanged, so skip

                    lda fromPiece                   ; new piece

                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2

                    jsr AddPieceMaterialValue

.same1

    ; and now the 'subtracts'

                    NEGEVAL

                    ldy originX12
                    lda __originalPiece
                    jsr AddPiecePositionValue       ; remove pos value for original position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same2                      ; unchanged, so skip

                    lda __originalPiece
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue       ; remove material for original type
.same2

                    NEGEVAL

    ; If there's a capture, we adjust the material value    

;                    lda __capturedPiece
;                    eor __originalPiece
;                    bpl .noCapture                  ; special-case capture rook castling onto king


                    lda __capturedPiece
                    and #PIECE_MASK
                    beq .noCapture
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue       ; -other colour = + my colour!
.noCapture

    ; }
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

        REFER InitialisePieceSquares
        REFER AdjustMaterialPositionalValue
        REFER EnPassantRemovePiece

        VEND AddPieceMaterialValue

    ; Adjust the material score based on the piece
    ; a = piece type + flags

                    and #PIECE_MASK
                    tay

                    lda #EVAL
                    sta SET_BANK;@3

                    clc
                    lda PieceValueLO,y
                    adc Evaluation
                    sta Evaluation
                    lda PieceValueHI,y
                    adc Evaluation+1
                    sta Evaluation+1
                    rts

;---------------------------------------------------------------------------------------------------


    DEF AddPiecePositionValue
    SUBROUTINE

        REFER InitialisePieceSquares
        REFER AdjustMaterialPositionalValue
        REFER EnPassantRemovePiece

        VAR __valPtr, 2
        VAR __valHi, 1

        VEND AddPiecePositionValue


    ; adds value of square piece is on to the evaluation
    ; note to do the subtraction as -( -x + val) == x - val
    
    ; y = square
    ; a = piece type (+flags)



                    cmp #128                        ; black = CS
                    and #PIECE_MASK
                    tax

                    lda #EVAL
                    sta SET_BANK;@3

    ; black pieces flip rows so we can use the same eval tables

                    tya
                    bcc .white
                    lda FlipSquareIndex,y
                    ;clc                    
.white
                    adc PosValVecLO,x
                    sta __valPtr
                    lda PosValVecHI,x
                    adc #0
                    sta __valPtr+1

                    ldy #0
                    sty __valHi
                    lda (__valPtr),y
                    bpl .sum
                    dec __valHi

.sum                clc
                    adc Evaluation
                    sta Evaluation
                    lda Evaluation+1
                    adc __valHi
                    sta Evaluation+1
                    rts


;---------------------------------------------------------------------------------------------------

    include "piece_vectors.asm"

;---------------------------------------------------------------------------------------------------

            CHECK_BANK_SIZE "BANK_GENERIC@2"

;---------------------------------------------------------------------------------------------------
;EOF
