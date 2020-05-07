; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1
    NEWBANK TWO


;---------------------------------------------------------------------------------------------------

    IF 0
    DEF SAFE_BackupBitmaps
    SUBROUTINE

        VEND SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    lda savedBank
                    sta SET_BANK
                    rts
    ENDIF

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
                    sty SET_BANK_RAM
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
                    sta SET_BANK_RAM
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

                    lda currentPly
                    sta SET_BANK_RAM
                    rts


;---------------------------------------------------------------------------------------------------

    DEF unmakeMove
    SUBROUTINE

        REFER negaMax
        VAR __unmake_capture, 1
        VAR __secondaryBlank, 1
        VEND unmakeMove

    ; restore the board evaluation to what it was at the start of this ply
    ; TODO: note: moved flag seems wrong on restoration

                    lda@PLY savedEvaluation
                    sta Evaluation
                    lda@PLY savedEvaluation+1
                    sta Evaluation+1

                    ldx movePtr
                    lda@PLY MoveFrom,x
                    sta fromX12
                    ldy@PLY MoveTo,x

                    lda@PLY restorePiece
                    pha
                    lda@PLY capturedPiece

                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y
                    ldy fromX12
                    pla
                    sta@RAM Board,y


                    lda currentPly
                    sta SET_BANK_RAM

    ; See if there are any 'secondary' pieces that moved
    ; here we're dealing with reverting a castling or enPassant move

                    lda@PLY secondaryPiece
                    beq .noSecondary
                    ldy@PLY secondaryBlank
                    sty __secondaryBlank
                    ldy@PLY secondarySquare


                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y                     ; put piece back

                    ldy __secondaryBlank
                    lda #0
                    sta@RAM Board,y                     ; blank piece origin

                    lda currentPly
                    sta SET_BANK_RAM


.noSecondary
                    SWAP
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_getMoveIndex
    SUBROUTINE

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    lda@PLY moveIndex
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetValid
    SUBROUTINE

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda ValidSquare,y
                    ldy savedBank
                    sty SET_BANK
                    rts



;---------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------

    DEF CopySetupForMarker
    SUBROUTINE

        REFER markerDraw
        REFER showPromoteOptions
        VAR __pieceColour, 1
        VAR __oddeven, 1
        VAR __pmcol, 1
        VEND CopySetupForMarker

                    lda squareToDraw
                    sec
                    ldy #10
.sub10              sbc #10
                    dey
                    bcs .sub10
                    sty __oddeven
                    adc #8
                    sta __pmcol
                    adc __oddeven

                    and #1
                    eor #1
                    beq .white
                    lda #36
.white
                    sta __pieceColour               ; actually SQUARE black/white

                    txa
                    clc
                    adc __pieceColour
                    sta __pieceColour

                    lda __pmcol
                    and #3

                    clc
                    adc __pieceColour
                    tay
                    rts

;---------------------------------------------------------------------------------------------------



;---------------------------------------------------------------------------------------------------

    DEF AddMove
    SUBROUTINE

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

.always             lda currentPly
                    sta SET_BANK_RAM
                    jsr AddMovePly
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    rts
                    
.abort              tya
                    tax
                    rts

;---------------------------------------------------------------------------------------------------

    DEF GenerateAllMoves
    SUBROUTINE

        REFER negaMax
        REFER quiesce
        REFER aiStepMoveGen
        REFER aiGenerateMoves
        REFER selectmove
        VAR __vector, 2
        VAR __masker, 2
        VAR __pieceFilter, 1
        VEND GenerateAllMoves

    ; Do the move generation in two passes - pawns then pieces
    ; This is an effort to get the alphabeta pruning happening with major pieces handled first in list

                    lda currentPly
                    sta SET_BANK_RAM
                    jsr NewPlyInitialise
    
                    lda #8                  ; pawns
                    sta __pieceFilter
                    jsr MoveGenX
                    lda #99
                    sta currentSquare
                    lda #0
                    sta __pieceFilter
                    jsr MoveGenX

                    lda currentPly
                    sta SET_BANK_RAM
                    jmp Sort



    DEF MoveGenX
    SUBROUTINE
    
                    ldx #100
                    bne .next2

    DEF MoveReturn


                      ldx currentSquare

.next2              lda #RAMBANK_BOARD
                    sta SET_BANK_RAM

.next               dex
                    cpx #22
                    bcc .exit

                    lda Board,x
                    beq .next
                    cmp #-1
                    beq .next
                    eor sideToMove
                    bmi .next
                    
;    DEF handleIt
;    SUBROUTINE


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
                    jmp (__vector)



.exit
                    rts

 
;---------------------------------------------------------------------------------------------------

    DEF ListPlayerMoves
    SUBROUTINE


                    lda #0
                    sta __quiesceCapOnly                ; gen ALL moves

                    lda #RAMBANK_PLY+1
                    sta currentPly
                    jsr GenerateAllMoves

                    ldx@PLY moveIndex
.scan               stx@PLY movePtr

                    jsr MakeMove

                    inc currentPly
                    jsr GenerateAllMoves

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    jsr unmakeMove

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
; TODO - is this valid?

    DEF markerDraw
    SUBROUTINE

        REFER SAFE_showMoveOptions
        VEND markerDraw
                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    jsr CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF GetP_MoveFrom
                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MoveFrom,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetP_MoveTo
    SUBROUTINE

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MoveTo,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetPiece
    SUBROUTINE

        REFER aiSelectDestinationSquare
        REFER aiQuiescent
        VEND GetPiece

    ; Retrieve the piece+flags from the movelist, given from/to squares
    ; Required as moves have different flags but same origin squares (e.g., castling)

                    lda currentPly
                    sta SET_BANK_RAM

                    jsr GetPieceGivenFromToSquares

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetP_MovePiece
    SUBROUTINE

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MovePiece,x
                    sty SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiComputerMove
    SUBROUTINE

        REFER AiStateMachine
        VEND aiComputerMove

 
                    lda #RAMBANK_PLY
                    sta currentPly                    
                    sta SET_BANK_RAM                ; switch in movelist
                    
                    lda #1
                    sta CTRLPF                      ; mirroring for thinkbars

                    jsr selectmove

                    lda #0
                    sta CTRLPF                      ; clear mirroring
                    sta PF1
                    sta PF2

                    lda@PLY bestMove
                    bpl .notComputer

    ; Computer could not find a valid move. It's checkmate or stalemate. Find which...

                    SWAP
                    jsr GenerateAllMoves
                    lda flagCheck
                    beq .gameDrawn

                    PHASE AI_CheckMate
                    rts


.gameDrawn          PHASE AI_Draw
                    rts
                    
.notComputer


                    lda #-1
                    sta cursorX12

                    PHASE AI_DelayAfterMove
.halted             rts



;---------------------------------------------------------------------------------------------------

    DEF aiSpecialMoveFixup
    SUBROUTINE

        COMMON_VARS_ALPHABETA
        REFER AiStateMachine
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

                    lda #BANK_EnPassantCheck
                    sta SET_BANK
                    jsr EnPassantCheck

    ENDIF


                    lda currentPly
                    sta SET_BANK_RAM
                    jsr  CastleFixupDraw

                    lda fromX12
                    sta squareToDraw

                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiDrawEntireBoard
    SUBROUTINE

        REFER AiStateMachine
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

                    ;jsr CopySinglePiece

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

    DEF PutBoard
                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y             ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetBoard
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda Board,y
                    ldy savedBank
                    sty SET_BANK
                    rts

;---------------------------------------------------------------------------------------------------


    DEF IsValidMoveFromSquare
    SUBROUTINE

        REFER aiSelectStartSquare
        VEND IsValidMoveFromSquare

    ; Does the square exist in the movelist?
    ; Return: y = -1 if NOT FOUND

                    lda cursorX12
                    sta fromX12

                    ldy currentPly
                    sty SET_BANK_RAM
                    jsr CheckMoveListFromSquare

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    IF ENPASSANT_ENABLED

    DEF EnPassantCheck
    SUBROUTINE

        REFER MakeMove
        REFER aiSpecialMoveFixup
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

                    lda #RAMBANK_BANK_EVAL
                    sta SET_BANK_RAM
                    sta savedBank

                    ldy originX12                   ; taken pawn's square
                    jsr EnPassantRemovePiece

.notEnPassant
    ; }

                    rts

    ENDIF
    

;---------------------------------------------------------------------------------------------------

    CHECK_BANK_SIZE "TWO"

;---------------------------------------------------------------------------------------------------
;EOF
