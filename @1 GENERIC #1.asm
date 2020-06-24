;---------------------------------------------------------------------------------------------------
; @1 GENERIC #1.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------

    SLOT 1           ; which bank this code switches to
    ROMBANK ONE


;---------------------------------------------------------------------------------------------------

    DEF CartInit
    SUBROUTINE

        REF StartupBankReset ;✅

        VEND CartInit


    ; See if we can come up with something 'random' for startup

                    ldy INTIM
                    bne .toR
                    ldy #$9A
.toR                sty rnd

                    lda #31
                    sta randomness

                    lda #0
                    sta SWBCNT                      ; console I/O always set to INPUT
                    sta SWACNT                      ; set controller I/O to INPUT
                    sta HMCLR

                    sta GRP0
                    sta GRP1
                    sta ENAM0
                    sta ENAM1
                    sta ENABL

    ; cleanup remains of title screen
                    ;sta GRP0
                    ;sta GRP1

                    lda #%111
                    sta NUSIZ0
                    sta NUSIZ1              ; quad-width

                    ;lda #%00000100
                    ;sta CTRLPF
                    lda #BACKGCOL
                    sta COLUBK

                    
                    lda #WHITE|HUMAN
                    sta sideToMove

                    rts


;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    SUBROUTINE

    ; Move a copy of the row bank template to the first 8 banks of RAM
    ; and then terminate the draw subroutine by substituting in a RTS on the last one

        REF StartupBankReset ;✅
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

                    ldx #ROMBANK_SHADOW_BOARD
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

        REF SetupBanks ;✅

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

    DEF InitialisePieceSquares
    SUBROUTINE

        REF COMMON_VARS
        REF StartupBankReset ;✅

        VAR __initPiece, 1
        VAR __initSquare, 1
        VAR __initListPtr, 1
        VAR __op, 1
        
        VEND InitialisePieceSquares

                    lda #0
                    sta Evaluation
                    sta Evaluation+1                ; tracks CURRENT value of everything (signed 16-bit)
                    sta enPassantPawn               ; no en-passant


                    PHASE StartClearBoard

                    ldx #0
.fillPieceLists


                    lda InitPieceList,x             ; colour/-1
                    beq .exit
                    sta __op             ; type
                    ldy InitPieceList+1,x           ; square
                    sty __initSquare

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda __op
                    sta@RAM Board,y
                    bpl .white

                    NEGEVAL
.white

                    stx __initListPtr

    ; Add the material value of the piece to the evaluation

                    lda __op
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue


    ; add the positional value of the piece to the evaluation 

                    ldy __initSquare
                    lda __op
                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK
                    jsr AddPiecePositionValue

                    lda __op             ; type/colour
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
    ; make sure illegal moves leaving K in check are removed

    .byte WHITE|N, 28
    .byte WHITE|K, 26

    .byte BLACK|Q, 29

    .byte 0 ;end

    ENDIF

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

    IF TEST_POSITION & 0
    ; Castling across/into check
    ; pawn promotion

        .byte WHITE|K, 26
        .byte WHITE|R, 29
        .byte BLACK|B, 45
        .byte WHITE|Q, 72
        .byte BLACK|N, 84
        .byte WHITE|WP,89

    ENDIF



    IF TEST_POSITION & 0
    ; En passant test

        .byte BLACK|BP, 88
        .byte BLACK|BP, 86

        .byte WHITE|WP|FLAG_MOVED, 67
        .byte WHITE|K, 52


    ENDIF

    IF TEST_POSITION & 0
    ; En passant test (white)

        .byte BLACK|BP|FLAG_MOVED, 53

        .byte WHITE|WP, 34
        .byte WHITE|K, 52


        .byte BLACK|BP, 88
        .byte WHITE|WP|FLAG_MOVED, 67


    ENDIF


    IF TEST_POSITION & 1
    ; castle

        .byte BLACK|R, 99
        .byte BLACK|K, 96
        .byte BLACK|BP, 89

        .byte WHITE|WP, 37
        .byte WHITE|WP, 38
        .byte WHITE|WP, 39
        .byte WHITE|R,29
        .byte WHITE|K, 26

    ENDIF




    IF TEST_POSITION & 0
    ; promote test

        .byte BLACK|K, 22
        .byte BLACK|N, 96

        .byte WHITE|WP, 87
        .byte WHITE|R,95
        .byte WHITE|R,94
        .byte WHITE|K, 52


    ENDIF



    IF 0


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

    DEF AddMoveSimple
    SUBROUTINE

        VEND AddMoveSimple

    ; add square in y register to movelist as destination (X12 format)
    ; [y]               to square (X12)
    ; currentSquare     from square (X12)
    ; currentPiece      piece.
    ;   ENPASSANT flag set if pawn double-moving off opening rank
    ; capture           captured piece

                    lda capture
                    bne .always
                    lda __quiesceCapOnly
                    bne .abort

.always             tya

                    ldy@PLY moveIndex
                    iny
                    sty@PLY moveIndex
                    
                    sta@PLY MoveTo,y
                    lda currentSquare
                    sta@PLY MoveFrom,y
                    lda currentPiece
                    sta@PLY MovePiece,y
                    lda capture
                    sta@PLY MoveCapture,y

.abort              rts


;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

        REF COMMON_VARS
        REF AiStateMachine ;✅
        VEND aiSpecialMoveFixup

                    lda INTIM
                    cmp #SPEEDOF_CopySinglePiece+4
                    bcs .cont
                    rts


.cont

                    PHASE DelayAfterPlaced


    ; Special move fixup

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr CastleFixupDraw

                    lda fromX12
                    sta squareToDraw

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiEPFlash
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiEPFlash

                    lda drawDelay
                    beq .deCount
                    dec drawDelay
                    rts

.deCount            lda drawCount
                    beq .flashDone2
                    dec drawCount

                    lda #10
                    sta drawDelay               ; "getting ready to move" flash

                    lda enPassantPawn
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0
                    rts

.flashDone2


                    lda #0                          ; on/off count
                    sta drawCount                   ; flashing for piece about to move
                    lda #0
                    sta drawDelay

                    jsr EnPassantRemoveCapturedPawn

                    ;lda #100
                    ;sta aiFlashDelay ;???

                    PHASE FinalFlash
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CastleFixupDraw
    SUBROUTINE

        REF aiSpecialMoveFixup ;✅
        VEND CastleFixupDraw

    ; guarantee flags for piece, post-move, are correct


                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@2

                    lda fromPiece
                    and #~FLAG_ENPASSANT
                    ora #FLAG_MOVED

                    ldy fromX12                 ; destinatino
                    sta@RAM Board,y


    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king


    IF CASTLING_ENABLED
                    CALL GenCastleMoveForRook;@3
                    bcs .phase
    ENDIF
    
                SWAP
                rts

.phase

    ; in this siutation (castle, rook moving) we do not change sides yet!

                    PHASE MoveIsSelected
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawEntireBoard
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine ;✅

        VEND aiDrawEntireBoard


                    lda INTIM
                    cmp #SPEEDOF_CopySinglePiece+4
                    bcc .exit

    ; We use [SLOT3] for accessing board

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    ldy squareToDraw
                    lda ValidSquare,y
                    bmi .isablank2

                    lda Board,y
                    beq .isablank
                    pha
                    lda #BLANK
                    sta@RAM Board,y

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM

                    ldy squareToDraw
                    pla
                    sta@RAM Board,y

.isablank           PHASE DrawPart2
                    rts

.isablank2          PHASE DrawPart3
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawPart2
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiDrawPart2

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0

    DEF aiDrawPart3
    SUBROUTINE

                    dec squareToDraw
                    lda squareToDraw
                    cmp #22
                    bcc .comp

                    PHASE DrawEntireBoard
                    rts

.comp

                    lda #-1
                    sta toX12                        ; becomes startup flash square
                    lda #36                         ; becomes cursor position
                    sta originX12


                    PHASE GenerateMoves
                    rts
                    

;---------------------------------------------------------------------------------------------------

    DEF aiMarchB
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF AiStateMachine
        VEND aiMarchB

    ; Draw the piece in the new square

                    lda fromX12
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0          ; draw the moving piece into the new square

                    lda #2                          ; snail trail delay
                    sta drawDelay

                    PHASE MarchToTargetB
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDraw
    SUBROUTINE
                    lda #$C0
                    sta COLUBK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiCheckMate
    SUBROUTINE
                    lda #$44
                    sta COLUBK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiQuiescent
    SUBROUTINE

        REF AiStateMachine
        VEND aiQuiescent

    ; Move has been selected

                    lda #-1
                    sta cursorX12

                    lda fromX12
                    sta originX12
                    CALL GetPiece;@3                ; from the movelist

                    ldy fromX12
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    eor fromPiece
                    and #PIECE_MASK                 ; if not the same piece board/movelist...
                    bne .promote                    ; promote a pawn

                    PHASE MoveIsSelected
                    rts

.promote            PHASE PromotePawnStart
                    rts


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
; EOF
