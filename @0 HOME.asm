;---------------------------------------------------------------------------------------------------
; @0 HOME.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------

    SLOT 0
    ROMBANK LOCKED_BANK


;---------------------------------------------------------------------------------------------------

    DEF StartupBankReset
    SUBROUTINE

        VEND StartupBankReset


                    ;CALL TitleScreen

                    CALL CartInit
                    CALL SetupBanks
                    CALL InitialisePieceSquares
                    jsr ListPlayerMoves;@0


.StartFrame


                    CALL InterlaceFrame


                    ldx platform
                    lda time64a,x
                    sta TIM64T

    ; LOTS OF PROCESSING TIME - USE IT

    IFCONST RAINBOW
                    CALL RainBoard
    ENDIF
    
                    jsr AiStateMachine


    IF ASSERTS
; Catch timer expired already
;                    bit TIMINT
;.whoops             bmi .whoops
    ENDIF


.wait               bit TIMINT
                    bpl .wait


    ; START OF VISIBLE SCANLINES


                    CALL longD


                    ldx #SLOT_DrawRow ; + BANK_DrawRow
                    stx SET_BANK_RAM
                    jsr DrawRow                     ; draw the ENTIRE visible screen!

                    CALL tidySc

                    jsr AiStateMachine

    lda INTIM
    cmp #20
    bcc .notnow                    

                    CALL SayIt ;GameSpeak
                    CALL PositionSprites


    IF 1
    ; "draw" sprite shapes into row banks

                    ldx #7
zapem               txa
                    clc
                    adc #SLOT_DrawRow
                    sta SET_BANK_RAM
                    CALL WriteBlank;@3
                    dex
                    bpl zapem

                    CALL WriteCursor;@3
    ENDIF

.notnow

.waitTime           bit TIMINT
                    bpl .waitTime
    sta WSYNC
    

                    jmp .StartFrame

time64a
    .byte TIME_PART_1, TIME_PART_1_PAL
     
;---------------------------------------------------------------------------------------------------

    DEF COMMON_VARS

        VAR __thinkbar, 1
        VAR __toggle, 1

        VAR __bestMove, 1
        VAR __alpha, 2
        VAR __beta, 2
        VAR __negaMax, 2
        VAR __value, 2

        VAR __quiesceCapOnly, 1

        VAR __originalPiece, 1
        VAR __capturedPiece, 1


        VAR testzp, 2
        VEND COMMON_VARS        


;---------------------------------------------------------------------------------------------------

    DEF ThinkBar
    SUBROUTINE

        REF COMMON_VARS
        REF negaMax ;✅
        REF quiesce ;✅

        VEND ThinkBar


    ; Check timer!

    IF 0
        lda INTIM
        bpl .notick
        lda #127
        sta T1024T
        inc testzp
        ;bne .notick
        inc testzp+1

        lda testzp+1
        asl
        sta COLUBK



.notick
    ENDIF


        IF DIAGNOSTICS

                    inc positionCount
                    bne .p1
                    inc positionCount+1
                    bne .p1
                    inc positionCount+2
.p1
        ENDIF

    ; The 'thinkbar' pattern...

                    lda #0
                    ldy INPT4
                    bmi .doThink
    
                    inc __thinkbar
                    lda __thinkbar
                    and #15
                    tay
                    lda rnd
                    and #6
                    ora TBcol,y
                    sta COLUPF

                    lda SynapsePattern,y
.doThink            sta PF2
                    sta PF1
                    sta PF0
                    rts


TBcol
.TBC SET 2
    REPEAT 16
    .byte .TBC
.TBC SET .TBC + 16
    REPEND

SynapsePattern

    .byte %11000001
    .byte %01100000
    .byte %00110000
    .byte %00011000
    .byte %00001100
    .byte %00000110
    .byte %10000011
    .byte %11000001

    .byte %10000011
    .byte %00000110
    .byte %00001100
    .byte %00011000
    .byte %00110000
    .byte %01100000
    .byte %11000001
    .byte %10000011


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE

    ; Common vairables...
    ; REQUIRES calling routines to "REF Variable_PieceShapeBuffer"

    TIMING CopySinglePiece, (2600)

        REF Variable_PieceShapeBuffer
        REF showMoveCaptures ;✅
        REF aiDrawEntireBoard ;✅
        REF aiDrawPart2 ;✅
        REF aiMarchB ;✅
        REF aiFlashComputerMove ;✅
        REF aiSelectDestinationSquare ;✅
        REF aiMarchA2 ;✅
        REF aiMarchB2 ;✅
        REF aiWriteStartPieceBlank ;✅
        REF aiChoosePromotePiece ;✅
        REF aiMarchToTargetB ;✅
        REF aiPromotePawnStart ;✅
        REF aiFinalFlash ;✅


        VEND CopySinglePiece

    ; WARNING: CANNOT USE VAR/OVERLAY IN ANY ROUTINE CALLING THIS!!
    ; ALSO CAN'T USE IN THIS ROUTINE
    ; This routine will STOMP on those vars due to __pieceShapeBuffer occupying whole overlay
    ; @2150 max
    ; = 33 TIM64T

                    CALL CopySetup;@2


    DEF InterceptMarkerCopy
    SUBROUTINE

        REF CopySinglePiece ;✅
        REF showPromoteOptions ;✅
        REF showMoveOptions ;✅

        VAR __psb, 2
        
        VEND InterceptMarkerCopy

    ; Copy a piece shape (3 PF bytes wide x 24 lines) to the RAM buffer
    ; y = piece index

                    lda #BANK_PIECE_VECTOR_BANK
                    sta SET_BANK;@2

                    lda PIECE_VECTOR_LO,y
                    sta __psb
                    lda PIECE_VECTOR_HI,y
                    sta __psb+1
                    lda PIECE_VECTOR_BANK,y
                    sta SET_BANK;@2

                    ldy #PIECE_SHAPE_SIZE-1
.copy               lda (__psb),y
                    sta __pieceShapeBuffer,y
                    dey
                    bpl .copy

                    lda squareToDraw
                    sec
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    adc #8
                    cmp #4                          ; CS = right side of screen

                    txa
                    ora #[SLOT2]
                    sta SET_BANK_RAM;@2             ; bank row

                    jsr CopyPieceToRowBitmap;@3
                    rts


;---------------------------------------------------------------------------------------------------

P SET 0
    MAC AIN
AI_{1} SET P
P SET P+1
    ENDM

    MAC LO
    .byte <ai{1}
    ENDM

    MAC HI
    .byte >ai{1}
    ENDM

    MAC BK
    .byte BANK_ai{1}
    ENDM


ONCEPERFRAME = 40

    MAC TABDEF ; {1} = macro to use
        
        {1} FlashComputerMove                       ; 0
        {1} BeginSelectMovePhase                    ; 1
        {1} SelectStartSquare                       ; 2
        {1} StartSquareSelected                     ; 3
        {1} DrawMoves                               ; 4
        {1} ShowMoveCaptures                        ; 5
        {1} SlowFlash                               ; 6
        {1} UnDrawTargetSquares                     ; 7
        {1} SelectDestinationSquare                 ; 8
        {1} Quiescent                               ; 9
        {1} ReselectDebounce                        ; 10
        {1} StartMoveGen                            ; 11
        {1} StepMoveGen                             ; 12
        {1} StartClearBoard                         ; 13
        {1} ClearEachRow                            ; 14
        {1} DrawEntireBoard                         ; 15
        {1} DrawPart2                               ; 16
        {1} DrawPart3                               ; 17
        {1} GenerateMoves                           ; 18
        {1} ComputerMove                            ; 19
        {1} MoveIsSelected                          ; 20
        {1} WriteStartPieceBlank                    ; 21
        {1} MarchToTargetA                          ; 22
        {1} MarchA2                                 ; 23
        {1} MarchB                                  ; 24
        {1} MarchToTargetB                          ; 25
        {1} MarchB2                                 ; 26
        {1} FinalFlash                              ; 27
        {1} SpecialMoveFixup                        ; 28
        {1} InCheckBackup                           ; 29
        {1} InCheckDelay                            ; 30
        {1} PromotePawnStart                        ; 31
        {1} RollPromotionPiece                      ; 32
        {1} ChoosePromotePiece                      ; 33
        {1} ChooseDebounce                          ; 34
        {1} CheckMate                               ; 35
        {1} Draw                                    ; 36
        {1} DelayAfterMove                          ; 37
        {1} DelayAfterMove2                         ; 38
        {1} DelayAfterPlaced                        ; 39
        {1} DelayAfterPlaced2                       ; 40
        {1} EPHandler                               ; 41
        {1} EPFlash                                 ; 42
        {1} DebounceSelect                          ; 43
        {1} InCheckBackupStart                      ; 44
        {1} RestoreBitmaps                          ; 45
        {1} WaitBitmap                              ; 46
        {1} MaskBitmapBackground                    ; 47
        {1} DrawBitmap2                             ; 48
        {1} DrawBitmap3                             ; 49

    ENDM

    TABDEF AIN

    DEF AiVectorLO
        TABDEF LO

    DEF AiVectorHI
        TABDEF HI

    DEF AiVectorBANK
        TABDEF BK


;---------------------------------------------------------------------------------------------------

    DEF AiStateMachine
    SUBROUTINE

        REF StartupBankReset ;✅
        VAR __aiVec, 2
        VEND AiStateMachine


    ; State machine vector setup - points to current routine to execute

                    ldx aiState
                    lda AiVectorLO,x
                    sta __aiVec
                    lda AiVectorHI,x
                    sta __aiVec+1

                    lda AiVectorBANK,x
                    sta SET_BANK
                    jmp (__aiVec)                 ; NOTE: could branch back to squeeze cycles


;---------------------------------------------------------------------------------------------------

    DEF GenerateAllMoves
    SUBROUTINE

        REF ListPlayerMoves ;✅
        REF aiComputerMove ;✅
        REF quiesce ;✅
        REF negaMax ;✅

        VAR __vector, 2
        VAR __pieceFilter, 1

        VEND GenerateAllMoves

    ; Do the move generation in two passes - pawns then pieces
    ; This is an effort to get the alphabeta pruning happening with major pieces handled first in list

    ;{

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty
    ; x must be preserved

                    lda currentPly
                    sta SET_BANK_RAM;@2

    ; note that 'alpha' and 'beta' are set externally!!

                    lda #-1
                    sta@PLY moveIndex           ; no valid moves
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



                    lda #8                  ; pawns
                    sta __pieceFilter
                    jsr MoveGenX
                    ;lda #99
                    ;sta currentSquare
                    lda #0
                    sta __pieceFilter
                    jsr MoveGenX

                    lda #BANK_Sort
                    sta SET_BANK
                    jmp Sort;@1



    DEF MoveGenX
    SUBROUTINE
    
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3             ; should be hardwired forever, right?

                    ldx #100
                    bne .next

    DEF MoveReturn

                    ldx currentSquare
.next               dex
                    cpx #22
                    bcc .exit

                    lda Board,x
                    beq .next
                    cmp #-1
                    beq .next
                    eor sideToMove
                    bmi .next
                    
                    stx currentSquare

                    eor sideToMove
                    and #~FLAG_CASTLE               ; todo: better part of the move, mmh?
                    sta currentPiece
                    and #PIECE_MASK
                    ora __pieceFilter
                    tay

                    lda HandlerVectorHI,y
                    sta __vector+1                    
                    lda HandlerVectorLO,y
                    sta __vector

                    lda HandlerVectorBANK,y
                    sta SET_BANK;@1

                    jmp (__vector)


.exit               lda #BANK_negaMax
                    sta SET_BANK
                    rts

    MAC HANDLEVEC ; {label}, {macro}
    DEF HandlerVector{1}
    
        .byte {2}MoveReturn
        .byte {2}MoveReturn ;byte {1}Handle_WHITE_PAWN        ; 1
        .byte {2}MoveReturn ;.byte {1}Handle_BLACK_PAWN        ; 2
        .byte {2}Handle_KNIGHT            ; 3
        .byte {2}Handle_BISHOP            ; 4
        .byte {2}Handle_ROOK              ; 5
        .byte {2}Handle_QUEEN             ; 6
        .byte {2}Handle_KING              ; 7

        .byte {2}MoveReturn
        .byte {2}Handle_WHITE_PAWN        ; 1
        .byte {2}Handle_BLACK_PAWN        ; 2
        .byte {2}MoveReturn;.byte {1}Handle_KNIGHT            ; 3
        .byte {2}MoveReturn;.byte {1}Handle_BISHOP            ; 4
        .byte {2}MoveReturn;.byte {1}Handle_ROOK              ; 5
        .byte {2}MoveReturn;.byte {1}Handle_QUEEN             ; 6
        .byte {2}MoveReturn;.byte {1}Handle_KING              ; 7

    ENDM


;    .byte 0     ; dummy to prevent page cross access on index 0

    HANDLEVEC LO, <
    HANDLEVEC HI, >
    HANDLEVEC BANK, BANK_


;---------------------------------------------------------------------------------------------------

    DEF ListPlayerMoves
    SUBROUTINE

    ; Build a list of (mostly) valid player moves. The list of all moves is generated, and then
    ; these are each verified by making the move and listing all opponent moves. If the opponent
    ; can capture the king, the move is invalidated by setting its "from" square to zero.

    ; The movelist is built in the second ply so as not to stomp on the movelist from the computer
    ; on the previous response. This allows the player movelist to be generated BEFORE the 
    ; computer's move has been visually shown on the screen. 

    ; This in turn requires the minimum memory for PLY banks to be 3 (computer, player, response)

        REF COMMON_VARS
        REF selectmove ;✅
        REF StartupBankReset ;✅

        VEND ListPlayerMoves


                    lda #0
                    sta __quiesceCapOnly                ; gen ALL moves

                    lda #RAMBANK_PLY+1
                    sta currentPly
                    
                    jsr GenerateAllMoves;@this

                    ldx@PLY moveIndex
.scan               stx@PLY movePtr

                    CALL MakeMove;@1

                    inc currentPly
                    jsr GenerateAllMoves;@this

                    dec currentPly

                    jsr unmakeMove;@this

                    lda flagCheck
                    beq .next

                    ldx@PLY movePtr
                    lda #0
                    sta@PLY MoveFrom,x              ; invalidate move (still in check!)

.next               ldx@PLY movePtr
                    dex
                    bpl .scan

                    rts


;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE

        REF Handle_KING ;✅
        REF Handle_QUEEN ;✅
        REF Handle_ROOK ;✅
        REF Handle_BISHOP ;✅
        REF Handle_KNIGHT ;✅
        REF Handle_WHITE_PAWN ;✅
        REF Handle_BLACK_PAWN ;✅

        VEND AddMove

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
                    tax

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
                    rts
                    
.abort              tya
                    tax
                    rts


;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE
                    rts


;---------------------------------------------------------------------------------------------------

    DEF unmakeMove
    SUBROUTINE

        REF selectmove ;✅
        REF ListPlayerMoves ;✅
        REF quiesce ;✅
        REF negaMax ;✅
        VEND unmakeMove

    ; restore the board evaluation to what it was at the start of this ply
    ; TODO: note: moved flag seems wrong on restoration??

                    lda currentPly
                    sta SET_BANK_RAM;@2
                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM;@3

                    lda@PLY savedEvaluation
                    sta Evaluation
                    lda@PLY savedEvaluation+1
                    sta Evaluation+1

                    lda@PLY virtualKingSquare
                    sta vkSquare
                    lda@PLY virtualKingSquare+1
                    sta vkSquare+1

                    lda@PLY enPassantSquare
                    sta enPassantPawn

                    ldx@PLY movePtr
                    ldy@PLY MoveFrom,x
                    lda@PLY restorePiece
                    sta@RAM Board,y

                    ldy@PLY MoveTo,x
                    lda@PLY capturedPiece
                    sta@RAM Board,y


    ; See if there are any 'secondary' pieces that moved
    ; here we're dealing with reverting a castling or enPassant move

                    lda@PLY secondaryPiece
                    beq .noSecondary
                    ldx@PLY secondarySquare
                    sta@RAM Board,x                     ; put piece back
                    ldy@PLY secondaryBlank
                    beq .noSecondary                    ; enpassant - no blanker square
                    lda #0
                    sta@RAM Board,y                     ; blank piece origin

.noSecondary        SWAP
                    rts


;---------------------------------------------------------------------------------------------------

    DEF showMoveCaptures
    SUBROUTINE

        REF aiShowMoveCaptures ;✅

        VAR __toSquareX12, 1
        VAR __fromPiece, 1
        VAR __aiMoveIndex, 1

        VEND showMoveCaptures

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked


.next               ldx aiMoveIndex
                    stx __aiMoveIndex
                    bmi .skip                       ; no moves in list

                    lda INTIM
                    cmp #20
                    bcc .skip

                    dec aiMoveIndex

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    lda@PLY MoveFrom,x
                    cmp fromX12
                    bne .next

                    lda@PLY MoveTo,x
                    sta __toSquareX12
                    tay

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    and #PIECE_MASK
                    beq .next

    ; There's something on the board at destination, so it's a capture
    ; Let's see if we are doing a pawn promote...

                    ldy fromX12

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3
                    lda Board,y
                    sta __fromPiece

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    lda@PLY MovePiece,x
                    eor __fromPiece
                    and #PIECE_MASK
                    beq .legit                  ; from == to, so not a promote

    ; Have detected a promotion duplicate - skip all 3 of them
    ; TODO: this will need reworking once moves are sorted

                    dec aiMoveIndex                 ; skip "KBRQ" promotes
                    dec aiMoveIndex
                    dec aiMoveIndex

.legit

        ;TIMECHECK CopySinglePiece, restoreIndex     ; not enough time to draw

                    lda __toSquareX12
                    sta squareToDraw

    ; WARNING - local variables will not survive the following call...!
                    jsr CopySinglePiece;@0

.skip               rts


;---------------------------------------------------------------------------------------------------

    DEF CopyPieceToRowBitmap
    SUBROUTINE

        REF Variable_PieceShapeBuffer
        REF InterceptMarkerCopy ;✅

        VEND CopyPieceToRowBitmap

                    ldy #17
                    bcs .rightSide

.copyPiece          lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap,y
                    sta@RAM ChessBitmap,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+18,y
                    sta@RAM ChessBitmap+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+36,y
                    sta@RAM ChessBitmap+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+54,y
                    sta@RAM ChessBitmap+54,y

.blank4             dey
                    bpl .copyPiece
                    rts

.rightSide

    SUBROUTINE

.copyPieceR         lda __pieceShapeBuffer,y
                    beq .blank1
                    eor ChessBitmap+PIECE_SHAPE_SIZE,y
                    sta@RAM ChessBitmap+PIECE_SHAPE_SIZE,y

.blank1             lda __pieceShapeBuffer+18,y
                    beq .blank2
                    eor ChessBitmap+PIECE_SHAPE_SIZE+18,y
                    sta@RAM ChessBitmap+PIECE_SHAPE_SIZE+18,y

.blank2             lda __pieceShapeBuffer+36,y
                    beq .blank3
                    eor ChessBitmap+PIECE_SHAPE_SIZE+36,y
                    sta@RAM ChessBitmap+PIECE_SHAPE_SIZE+36,y

.blank3             lda __pieceShapeBuffer+54,y
                    beq .blank4
                    eor ChessBitmap+PIECE_SHAPE_SIZE+54,y
                    sta@RAM ChessBitmap+PIECE_SHAPE_SIZE+54,y

.blank4             dey
                    bpl .copyPieceR
                    rts


;---------------------------------------------------------------------------------------------------

    DEF EnPassantRemoveCapturedPawn
    SUBROUTINE

        REF aiSpecialMoveFixup
        VEND EnPassantRemoveCapturedPawn

                    ldy enPassantPawn
                    beq .exit


                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3

    ; Account for the opponent pawn being removed
    ; Effectively ADD the values to our current score

                    lda sideToMove
                    eor #128
                    and #128
                    ora #WP                         ; == BP in this usage
                    
                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK;@2
                    jsr AddPiecePositionValue       ; remove pos value for original position

                    lda #WP                         ; == BP
                    ldx #BANK_AddPieceMaterialValue
                    stx SET_BANK;@2
                    jsr AddPieceMaterialValue       ; remove material for original type

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM;@3

                    ldx enPassantPawn
                    lda #0
                    sta@RAM Board,x


.exit               rts


;---------------------------------------------------------------------------------------------------

    END_BANK
    
;---------------------------------------------------------------------------------------------------
; EOF
