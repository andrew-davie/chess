; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1           ; which bank this code switches to
    NEWBANK ONE


;---------------------------------------------------------------------------------------------------
; ... the above is a (potentially) RAM-copied section -- the following is ROM-only.  Note that
; we do not configure a 1K boundary, as we con't really care when the above 'RAM'
; bank finishes.  Just continue on from where it left off...
;---------------------------------------------------------------------------------------------------

    DEF CartInit
    SUBROUTINE

        REFER StartupBankReset
        VEND CartInit

                    sei
                    cld
    ; See if we can come up with something 'random' for startup

                    ldy INTIM
                    bne .toR
                    ldy #$9A
.toR                sty rnd

                    lda #255
                    sta randomness

                    lda #0
                    sta SWBCNT                      ; console I/O always set to INPUT
                    sta SWACNT                      ; set controller I/O to INPUT
                    sta HMCLR

    ; cleanup remains of title screen
                    sta GRP0
                    sta GRP1

                    lda #%00010000                  ; double width missile, double width player
                    sta NUSIZ0
                    sta NUSIZ1

                    lda #%100                       ; players/missiles BEHIND BG
                    sta CTRLPF
                    lda #%111
                    sta NUSIZ0
                    sta NUSIZ1              ; quad-width

                    lda #%00000100
                    sta CTRLPF
                    lda #BACKGCOL
                    sta COLUBK

                    
                    lda #WHITE          ;tmp+RAMBANK_PLY
                    sta sideToMove

                    rts


;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    SUBROUTINE

    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

        REFER StartupBankReset
        VAR __plyBank, 1
        VEND SetupBanks
    
    ; Copy the bitmap shadow into the first 8 RAM banks via x(SLOT3)-->y(SLOT2)

.ROWBANK SET 0
    REPEAT 8
                    ldx #BANK_SHADOW_ChessBitmap
                    ldy #[SLOT3] + .ROWBANK
                    jsr CopyShadowROMtoRAM
.ROWBANK SET .ROWBANK+1
    REPEND


    ; Patch the final row's "loop" to a RTS

                    ldx #[SLOT2] + 7                    ; last ROW BITMAP bank
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta@RAM SELFMOD_RTS_ON_LAST_ROW



    ; copy the BOARD/MOVES bank

                    ldx #SHADOW_BOARD
                    ldy #RAMBANK_BOARD
                    jsr CopyShadowROMtoRAM              ; this auto-initialises Board too


    ; copy the PLY banks
    ; If there's no content (only variable decs) then we don't really need to do this.

;.PLY SET 0
;    REPEAT PLY_BANKS

;                    ldx #SHADOW_PLY
;                    ldy #RAMBANK_PLY + .PLY   
                    ;jsr CopyShadowROMtoRAM
;.PLY SET .PLY + 1                    
;    REPEND

    ; copy the evaluation code/tables
    ; 3E+ moved from RAM to ROM

;                    ldx #[SLOT2] + SHADOW_EVAL
;                    ldy #[SLOT3] + EVAL
;                    jsr CopyShadowROMtoRAM


;                    ldy #RAMBANK_RAM_PIECELIST
;                    ldx #ROM_PIECELIST
;                    jsr CopyShadowROMtoRAM

                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopyShadowROMtoRAM
    SUBROUTINE

        REFER SetupBanks
        VEND CopyShadowROMtoRAM

    ; Copy a whole ROM SHADOW into a destination RAM 512 byte bank
    ; used to setup callable RAM code from ROM templates

    ; x = source ROM bank
    ; y = destination RAM bank (preserved)

                    stx SET_BANK
                    sty SET_BANK_RAM

                    ldx #0
.copyPage           lda $F800,x
                    sta@RAM $FC00,x
                    lda $F900,x
                    sta@RAM $FD00,x
                    dex
                    bne .copyPage
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CallClear
    SUBROUTINE

    IF 0
        REFER aiClearEachRow
    ENDIF
        VEND CallClear

    IF 0
        ; No transient variable dependencies/calls

                    sty SET_BANK_RAM
                    jsr ClearRowBitmap
    ENDIF                    
                    rts


;---------------------------------------------------------------------------------------------------

    DEF InitialisePieceSquares
    SUBROUTINE

        REFER StartupBankReset
        VAR __initPiece, 1
        VAR __initSquare, 1
        VAR __initListPtr, 1
        VEND InitialisePieceSquares

;---------------------------------------------------------------------------------------------------

    DEF InitPieceLists
    SUBROUTINE

        REFER InitialisePieceSquares
        VEND InitPieceLists


                    lda #0
                    sta Evaluation
                    sta Evaluation+1                ; tracks CURRENT value of everything (signed 16-bit)
                    sta enPassantPawn               ; no en-passant


                    PHASE AI_StartClearBoard

                    ldx #0
.fillPieceLists


                    lda InitPieceList,x             ; colour/-1
                    beq .exit
                    sta __originalPiece             ; type
                    ldy InitPieceList+1,x           ; square
                    sty __initSquare

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda __originalPiece
                    sta@RAM Board,y
                    bpl .white

                    NEGEVAL
.white

    ; Add the material value of the piece to the evaluation

                    lda __originalPiece
                    jsr AddPieceMaterialValue

                    stx __initListPtr

    ; add the positional value of the piece to the evaluation 

                    ldy __initSquare
                    lda __originalPiece
                    jsr AddPiecePositionValue

                    lda __originalPiece             ; type/colour
                    bpl .white2
                    NEGEVAL
.white2

                    ldx __initListPtr
                    inx
                    inx
                    bpl .fillPieceLists

.exit
                    rts


InitPieceList


    IF !TEST_POSITION

    .byte WHITE|Q, 25
    .byte WHITE|B, 24
    .byte WHITE|B, 27
    .byte WHITE|R, 22
    .byte WHITE|R, 29
    .byte WHITE|N, 23
    .byte WHITE|N, 28

    .byte WHITE|WP, 35
    .byte WHITE|WP, 36
    .byte WHITE|WP, 34
    .byte WHITE|WP, 37
    .byte WHITE|WP, 33
    .byte WHITE|WP, 38
    .byte WHITE|WP, 32
    .byte WHITE|WP, 39

    .byte WHITE|K, 26

    .byte BLACK|Q, 95
    .byte BLACK|B, 94
    .byte BLACK|B, 97
    .byte BLACK|R, 92
    .byte BLACK|R, 99
    .byte BLACK|N, 93
    .byte BLACK|N, 98

    .byte BLACK|BP, 85
    .byte BLACK|BP, 86
    .byte BLACK|BP, 84
    .byte BLACK|BP, 87
    .byte BLACK|BP, 83
    .byte BLACK|BP, 88
    .byte BLACK|BP, 82
    .byte BLACK|BP, 89

    .byte BLACK|K, 96

    .byte 0 ;end

    ELSE ; test position...


    IF 0

        .byte WHITE|K, 28
        .byte WHITE|WP, 37
        .byte WHITE|WP, 38
        .byte WHITE|WP, 53
        .byte WHITE|WP, 49
        .byte WHITE|WP, 32
        .byte WHITE|R, 27
        .byte WHITE|B, 46
        .byte WHITE|R, 54

        .byte BLACK|BP, 56
        .byte BLACK|BP, 87
        .byte BLACK|BP, 88
        .byte BLACK|BP, 89
        .byte BLACK|BP, 84
        .byte BLACK|B, 66
        .byte BLACK|R, 69
        .byte BLACK|K, 98

        .byte BLACK|R, 92



    ENDIF


    IF 0
    ; En passant test

        .byte BLACK|BP, 88
        .byte BLACK|BP, 86

        .byte WHITE|WP, 67
        .byte WHITE|K, 52


    ENDIF




    IF 1


    ;.byte BLACK|R, 97
    .byte BLACK|K, 98
    .byte BLACK|BP, 87
    .byte BLACK|BP, 88
    .byte BLACK|BP, 89
;    .byte BLACK|B, 76


    .byte WHITE|R,28
    .byte WHITE|Q,58
 ;   .byte WHITE|N,65
    ENDIF

    IF 0
        ;.byte WHITE|WP, 56


    .byte BLACK|K, 98


    .byte WHITE|R,29
    .byte WHITE|Q,49
    .byte WHITE|N,65
    ENDIF 
    .byte 0 ;end

    ENDIF


;---------------------------------------------------------------------------------------------------

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.

    ; First, nominate referencing subroutines so that local variables can be adjusted properly

        ;TODO REFER negaMax
        ;TODO REFER MakeMove
        ;TODO REFER aiMoveIsSelected
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

    DEF AddPiecePositionValue
    SUBROUTINE

        REFER AdjustMaterialPositionalValue
        REFER EnPassantRemovePiece
        REFER InitPieceLists
        REFER negaMax
        REFER quiesce

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

    DEF EnPassantRemovePiece
    SUBROUTINE

        ;TODO REFER MakeMove
    IF ENPASSANT_ENABLED
        REFER EnPassantCheck
    ENDIF
        VAR __y, 1
        VAR __col, 1
        VEND EnPassantRemovePiece


    ; Based on piece square, adjust material and position value with piece deleted
    ; y = piece square

                    sty __y

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    sta __col
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; adding for opponent = taking
                    
                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddPieceMaterialValue
    SUBROUTINE

        REFER AdjustMaterialPositionalValue
        REFER InitialisePieceSquares
        REFER EnPassantRemovePiece
        REFER InitPieceLists
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




    IF 0
        DEF IncVal
    SUBROUTINE

        ldx #99
.higher  clc
        lda@RAM PositionalValue_PAWN_BLACK,x
        adc #10
        cmp #$7F
        bcc .norm
        lda #$7f
.norm   sta@RAM PositionalValue_PAWN_BLACK,x
        dex
        bpl .higher
        rts
    ENDIF
;---------------------------------------------------------------------------------------------------

    ALLOCATE FlipSquareIndex, 100

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

    DEF MakeMove
    SUBROUTINE

        REFER negaMax
        VAR __capture, 1
        VAR __restore, 1
        VEND MakeMove

    ; Do a move without any GUI stuff
    ; This function is ALWAYS paired with "unmakeMove" - a call to both will leave board
    ; and all relevant flags in original state. This is NOT used for the visible move on the
    ; screen.


    ; fromPiece     piece doing the move
    ; fromX12       current square X12
    ; originX12     starting square X12
    ; toX12         ending square X12

    ; BANK:SLOT2 = currentPly


    ; There are potentially "two" moves, with the following
    ; a) Castling, moving both rook and king
    ; b) en-Passant, capturing pawn on "odd" square
    ; These both set "secondary" movers which are used for restoring during unmakeMove

                    lda #0
                    sta@PLY secondaryPiece

                    ldx@PLY movePtr
                    lda@PLY MoveFrom,x
                    sta fromX12
                    sta originX12
                    lda@PLY MoveTo,x
                    sta toX12
                    lda@PLY MovePiece,x
                    sta fromPiece                   

.move               jsr AdjustMaterialPositionalValue

    ; Modify the board
    
                    ldy #RAMBANK_BOARD
                    sty SET_BANK_RAM;@3
                    ldy originX12
                    lda@RAM Board,y
                    sta __restore
                    lda #0
                    sta@RAM Board,y
                    ldy toX12
                    lda@RAM Board,y
                    sta __capture
                    lda fromPiece
                    and #PIECE_MASK|FLAG_COLOUR
                    ora #FLAG_MOVED
                    sta@RAM Board,y

                    lda currentPly
                    sta SET_BANK_RAM;@2
                    lda __capture
                    sta@PLY capturedPiece
                    lda __restore
                    sta@PLY restorePiece

    IF CASTLING_ENABLED

        ; If the FROM piece has the castle bit set (i.e., it's a king that's just moved 2 squares)
        ; then we find the appropriate ROOK, set the secondary piece "undo" information, and then
        ; redo the moving code (for the rook, this time).

                    jsr GenCastleMoveForRook
                    bcs .move                       ; move the rook!
    ENDIF


    IF ENPASSANT_ENABLED    
                    jsr EnPassantCheck
                    beq .notEnPassant
                    jsr EnPassantRemovePiece        ; y = origin X12
.notEnPassant
    ENDIF

    ; Swap over sides

                    NEGEVAL
                    SWAP
                    rts

;---------------------------------------------------------------------------------------------------

    DEF CastleFixupDraw
    SUBROUTINE

        REFER aiSpecialMoveFixup
        VEND CastleFixupDraw

    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king


    IF CASTLING_ENABLED
                    jsr GenCastleMoveForRook
                    bcs .phase
    ENDIF
    
                SWAP
                rts

.phase

    ; in this siutation (castle, rook moving) we do not change sides yet!

                    PHASE AI_MoveIsSelected
                    rts



KSquare             .byte 24,28,94,98
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97


;---------------------------------------------------------------------------------------------------

    DEF GenCastleMoveForRook
    SUBROUTINE

        REFER MakeMove
        REFER CastleFixupDraw
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

    CHECK_BANK_SIZE "BANK_GENERIC@1#1"

;---------------------------------------------------------------------------------------------------
; EOF
