;---------------------------------------------------------------------------------------------------
; @2 GENERIC #3.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------

    SLOT 2
    ROMBANK GENERIC_BANK@2#1

;    DEFINE_1K_SEGMENT DECODE_LEVEL_SHADOW

    IF PLUSCART = YES
            .byte "ChessAPI.php", #0      //TODO: change!
	        .byte "pluscart.firmaplus.de", #0
    ENDIF

STELLA_AUTODETECT dc "TJ3E" ; 3E+ autodetect


;---------------------------------------------------------------------------------------------------

    DEF tidySc
    SUBROUTINE

        REF StartupBankReset ;✅
        VEND tidySc

                    lda #0
                    sta PF0
                    sta PF1
                    sta PF2
                    sta GRP0
                    sta COLUBK

                    lda #%01000010                  ; bit6 is not required
                    ;sta VBLANK                      ; end of screen - enter blanking

; END OF VISIBLE SCREEN
; HERE'S SOME TIME TO DO STUFF

;                    lda #TIME_PART_2
;                    sta TIM64T

                    ldx platform
                    lda time64b,x
                    sta TIM64T
                    rts

time64b
    .byte TIME_PART_2, TIME_PART_2_PAL
    

;---------------------------------------------------------------------------------------------------

    DEF longD
    SUBROUTINE

        REF StartupBankReset ;✅
        VEND longD

                    sta WSYNC

                    jsr _rts
                    jsr _rts
                    jsr _rts
                    SLEEP 7

                    ldx #0
                    stx VBLANK
_rts                rts


;---------------------------------------------------------------------------------------------------

    DEF aiStartClearBoard
    SUBROUTINE

        REF AiStateMachine ;✅
        VEND aiStartClearBoard

                    ldx #8
                    stx drawCount                   ; = bank

                    lda #-1
                    sta cursorX12

                    PHASE ClearEachRow
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiClearEachRow
    SUBROUTINE

        REF AiStateMachine ;✅
        VEND aiClearEachRow

                    dec drawCount
                    bmi .bitmapCleared

    ; switch in RAM bank for ROW

                    lda drawCount
                    ora #SLOT1
                    sta SET_BANK_RAM;@1

                    CALL ClearRowBitmap;@3
                    rts

.bitmapCleared

    lda #RAMBANK_BOARD
    sta SET_BANK_RAM;@3

    ldx #99
.clRndArray    txa
    sta@RAM RandomBoardSquare,x
    dex
    bpl .clRndArray


    ldx #99
.swapRnd

    lda ValidSquare,x
    bmi .nextSq

    NEXT_RANDOM
    and #127
    cmp #100
    bcs .nextSq
    tay
    lda ValidSquare,y
    bmi .nextSq

    lda RandomBoardSquare,x
    pha
    lda RandomBoardSquare,y
    sta@RAM RandomBoardSquare,x
    pla
    sta@RAM RandomBoardSquare,y
.nextSq    dex
    bpl .swapRnd


                    lda #99
                    sta squareToDraw

                    PHASE DrawEntireBoard
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiMoveIsSelected
    SUBROUTINE

        REF COMMON_VARS
        REF AiStateMachine ;✅
        VEND aiMoveIsSelected


    ; Both computer and human have now seleted a move, and converge here


    ; fromPiece     piece doing the move
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12

                    jsr EnPassantFixupDraw

        ; get the piece types from the board

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    ldy originX12
                    lda Board,y
                    sta __originalPiece
                    ldy toX12
                    lda Board,y
                    sta __capturedPiece

        ;TODO: what about castling...?

                    jsr AdjustMaterialPositionalValue;@this



                    lda #0
                    sta previousPiece
                    sta drawDelay

                    lda #10                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move

                    PHASE WriteStartPieceBlank
.idleErase          rts


;---------------------------------------------------------------------------------------------------

    DEF EnPassantFixupDraw
    SUBROUTINE

    ; {
    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

                    ldx #0                          ; (probably) NO en-passant this time

                    lda fromPiece
                    tay

                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    eor fromPiece                   ; clear FLAG_ENPASSANT
                    sta fromPiece

                    ldx toX12                       ; this IS an en-passantable opening, so record the square

    ; set the secondary piece movement info - this allows move/unmakemove to work for enpassant

                    lda #0
                    sta@PLY secondaryBlank
                    stx@PLY secondarySquare
                    sty@PLY secondaryPiece

.noep
                    stx enPassantPawn               ; capturable square for en-passant move (or none)
    ; }

                    rts

;---------------------------------------------------------------------------------------------------

    DEF CopySetup
    SUBROUTINE

        REF CopySinglePiece ;✅

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

        REF COMMON_VARS
        REF MakeMove ;✅
        REF aiMoveIsSelected ;✅
        VEND AdjustMaterialPositionalValue

    ; fromPiece     piece doing the move (promoted type)
    ; fromX12       current square
    ; originX12     starting square
    ; toX12         ending square


    ; {
    ;   adjust the positional value  (originX12 --> fromX12)

                    ldy toX12                       ; already loaded
                    lda fromPiece
                    jsr AddPiecePositionValue       ; add pos value for new position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same1                      ; unchanged, so skip

                    lda fromPiece                   ; new piece
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
                    jsr AddPieceMaterialValue       ; -other colour = + my colour!
.noCapture

    ; }
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

        REF COMMON_VARS
        REF InitialisePieceSquares ;✅
        REF AdjustMaterialPositionalValue ;✅
        ;REF EnPassantRemovePiece ;✅
        VEND AddPieceMaterialValue

    ; Adjust the material score based on the piece
    ; a = piece type + flags

                    and #PIECE_MASK
                    tay

                    clc
                    lda PieceValueLO,y
                    adc Evaluation
                    sta Evaluation
                    lda PieceValueHI,y
                    adc Evaluation+1
                    sta Evaluation+1
                    rts



    MAC VALUETABLE
    .byte {1}(0)      ; blank
    .byte {1}(100)    ; white P
    .byte {1}(100)    ; black P !!
    .byte {1}(320)    ; N
    .byte {1}(375)    ; B
    .byte {1}(575)    ; R
    .byte {1}(900)    ; Q
    .byte {1}(10000)  ; K
    ENDM

PieceValueLO
        VALUETABLE <

PieceValueHI
        VALUETABLE >


;---------------------------------------------------------------------------------------------------

    DEF AddPiecePositionValue
    SUBROUTINE

        REF InitialisePieceSquares ;✅
        REF AdjustMaterialPositionalValue ;✅
        ;REF EnPassantRemovePiece ;✅
        VAR __valPtr, 2
        VEND AddPiecePositionValue


    ; adds value of square piece is on to the evaluation
    ; note to do the subtraction as -( -x + val) == x - val
    
    ; y = square
    ; a = piece type (+flags)



                    cmp #128                        ; black = CS
                    and #PIECE_MASK
                    tax

                    lda #ROMBANK_EVALUATE
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
                    lda (__valPtr),y
                    bpl .sum
                    dey

.sum                ;clc
                    adc Evaluation
                    sta Evaluation
                    tya
                    adc Evaluation+1
                    sta Evaluation+1
                    rts


FlipSquareIndex

    .byte 0,0,0,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0,0,0

.SQBASE SET 90-1
    REPEAT 8
    .byte 0,0
.SQX SET 2
    REPEAT 8
    .byte (.SQBASE+.SQX)
.SQX SET .SQX + 1
    REPEND
.SQBASE SET .SQBASE - 10
    REPEND


;---------------------------------------------------------------------------------------------------

    include "piece_vectors.asm"


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
;EOF
