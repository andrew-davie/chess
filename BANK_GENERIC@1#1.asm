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

        REFER StartupBankReset ;✅

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

        REFER StartupBankReset ;✅

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

        REFER SetupBanks ;✅

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
        REFER aiClearEachRow    ;TODO
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

        REFER StartupBankReset ;✅

        VAR __initPiece, 1
        VAR __initSquare, 1
        VAR __initListPtr, 1
        
        VEND InitialisePieceSquares

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

                    stx __initListPtr

    ; Add the material value of the piece to the evaluation

                    lda __originalPiece
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue


    ; add the positional value of the piece to the evaluation 

                    ldy __initSquare
                    lda __originalPiece
                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK
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

    IF 1

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


    IF 0
    ; En passant test

        .byte BLACK|BP, 88
        .byte BLACK|BP, 86

        .byte WHITE|WP, 67
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

    DEF EnPassantRemovePiece
    SUBROUTINE

        REFER MakeMove

    IF ENPASSANT_ENABLED
        REFER EnPassantCheck ;✅
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
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue       ; adding for opponent = taking

                    lda __col
                    ldy __y
                    jsr AddPiecePositionValue       ; (same bank) adding for opponent = taking
                    
                    rts


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

    IF 0
    DEF SAFE_BackupBitmaps
    SUBROUTINE

        REFER aiInCheckBackup
        VEND SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    rts
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

        COMMON_VARS_ALPHABETA
        
        REFER AiStateMachine ;✅

        VEND aiSpecialMoveFixup

                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
                    bcs .cont
                    rts


.cont

                    PHASE AI_DelayAfterPlaced


    ; Special move fixup

    IF ENPASSANT_ENABLED

    ; Handle en-passant captures
    ; The (dual-use) FLAG_ENPASSANT will have been cleared if it was set for a home-rank move
    ; but if we're here and the flag is still set, then it's an actual en-passant CAPTURE and we
    ; need to do the appropriate things...

                    jsr EnPassantCheck

    ENDIF


                    lda currentPly
                    sta SET_BANK_RAM

                    jsr  CastleFixupDraw

                    lda fromX12
                    sta squareToDraw

                    rts


;---------------------------------------------------------------------------------------------------

    DEF CastleFixupDraw
    SUBROUTINE

        REFER aiSpecialMoveFixup ;✅

        VEND CastleFixupDraw

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

                    PHASE AI_MoveIsSelected
                    rts



KSquare             .byte 24,28,94,98
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97


;---------------------------------------------------------------------------------------------------

    DEF aiDrawEntireBoard
    SUBROUTINE

        REFER AiStateMachine ;✅

        VEND aiDrawEntireBoard


                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
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

                    jsr CopySinglePiece;@0

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM

                    ldy squareToDraw
                    pla
                    sta@RAM Board,y

.isablank           PHASE AI_DrawPart2
                    rts

.isablank2          PHASE AI_DrawPart3
.exit               rts


;---------------------------------------------------------------------------------------------------

    IF ENPASSANT_ENABLED

    DEF EnPassantCheck
    SUBROUTINE

        REFER MakeMove ;✅
        REFER aiSpecialMoveFixup ;✅
        VEND EnPassantCheck

    ; {
    ; With en-passant flag, it is essentially dual-use.
    ; First, it marks if the move is *involved* somehow in an en-passant
    ; if the piece has MOVED already, then it's an en-passant capture
    ; if it has NOT moved, then it's a pawn leaving home rank, and sets the en-passant square

                    ldy enPassantPawn               ; save from previous side move

                    ldx #0                          ; (probably) NO en-passant this time
                    lda fromPiece
                    and #FLAG_ENPASSANT|FLAG_MOVED
                    cmp #FLAG_ENPASSANT
                    bne .noep                       ; HAS moved, or not en-passant

                    eor fromPiece                   ; clear FLAG_ENPASSANT
                    sta fromPiece

                    ldx fromX12                     ; this IS an en-passantable opening, so record the square
.noep               stx enPassantPawn               ; capturable square for en-passant move (or none)

    ; }


    ; Check to see if we are doing an actual en-passant capture...

    ; NOTE: If using test boards for debugging, the FLAG_MOVED flag is IMPORTANT
    ;  as the en-passant will fail if the taking piece does not have this flag set correctly

                    lda fromPiece
                    and #FLAG_ENPASSANT
                    beq .notEnPassant               ; not an en-passant, or it's enpassant by a MOVED piece


    ; {

    ; Here we are the aggressor and we need to take the pawn 'en passant' fashion
    ; y = the square containing the pawn to capture (i.e., previous value of 'enPassantPawn')

    ; Remove the pawn from the board and piecelist, and undraw

                    sty squareToDraw
                    jsr CopySinglePiece;@0          ; undraw captured pawn

                    lda #EVAL
                    sta SET_BANK;@3

                    ldy originX12                   ; taken pawn's square
                    jsr EnPassantRemovePiece

.notEnPassant
    ; }

                    rts

    ENDIF
    

;---------------------------------------------------------------------------------------------------

    DEF aiDrawPart2
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawPart2

                    jsr CopySinglePiece;@0

    DEF aiDrawPart3
    SUBROUTINE

                    dec squareToDraw
                    lda squareToDraw
                    cmp #22
                    bcc .comp

                    PHASE AI_DrawEntireBoard
                    rts

.comp

                    lda #-1
                    sta toX12                        ; becomes startup flash square
                    lda #36                         ; becomes cursor position
                    sta originX12


                    PHASE AI_GenerateMoves
                    rts
                    

;---------------------------------------------------------------------------------------------------

    DEF aiMarchB
    SUBROUTINE

        REFER AiStateMachine
        VEND aiMarchB

    ; Draw the piece in the new square

                    lda fromX12
                    sta squareToDraw

                    jsr CopySinglePiece;@0          ; draw the moving piece into the new square

                    lda #10                          ; snail trail delay ??
                    sta drawDelay

                    PHASE AI_MarchToTargetB
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

    CHECK_BANK_SIZE "BANK_GENERIC@1#1"

;---------------------------------------------------------------------------------------------------
; EOF
