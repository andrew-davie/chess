
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

                    CALL AdjustMaterialPositionalValue;@1

                    lda #0
                    sta previousPiece
                    sta drawDelay

                    lda #10                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move

                    PHASE AI_WriteStartPieceBlank
.idleErase          rts


;---------------------------------------------------------------------------------------------------

    DEF CopySetup;@2 - uses @3
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

    include "piece_vectors.asm"

;---------------------------------------------------------------------------------------------------

            CHECK_BANK_SIZE "BANK_GENERIC@2"

;---------------------------------------------------------------------------------------------------
;EOF
