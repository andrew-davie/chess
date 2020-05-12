; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

    SLOT 1
    NEWBANK TWO


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

    DEF AddMoveSlider
    SUBROUTINE

        REFER Handle_BISHOP
        REFER Handle_ROOK
        REFER Handle_QUEEN
        VEND AddMoveSlider

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

.always
                    tya
                    
                    ldy@PLY moveIndex
                    iny
                    sty@PLY moveIndex
                    
                    sta@PLY MoveTo,y
                    tax                             ; used for continuation of sliding moves
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

    jsr debug ;tmp

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

                    lda #EVAL
                    sta SET_BANK;@3

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
