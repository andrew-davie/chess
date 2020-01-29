; Copyright (C)2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------
; Define the RAM banks
; A "PLY" bank represents all the data required on any single ply of the search tree.
; The banks are organised sequentially, MAX_PLY of them starting at RAMBANK_PLY
; The startup code copies the ROM shadow into each of these PLY banks, and from then on
; they act as independant switchable banks usable for data on each ply during the search.
; A ply will hold the move list for that position


MAX_PLY  = 10
    NEWRAMBANK PLY                ; RAM bank for holding the following ROM shadow
    REPEAT MAX_PLY-1
        NEWRAMBANK .DUMMY_PLY
    REPEND


;---------------------------------------------------------------------------------------------------
; and now the ROM shadow - this is copied to ALL of the RAM ply banks

    NEWBANK BANK_PLY                   ; ROM SHADOW

;---------------------------------------------------------------------------------------------------
; The piece-lists
; ONLY the very first bank piecelist is used - all other banks switch to the first for
; piecelist usage. Note that this initialisation (below) comes from the shadow ROM/RAM copy
; but this needs to be initialised programatically on new game.

; We have TWO piecelists, in different banks
; WHITE pieces in bank BANK_PLY
; BLACK pieces in bank BANK_PLY+1


    OPTIONAL_PAGEBREAK "PieceSquare", 16
    DEFINE_SUBROUTINE PieceSquare

#if 1
    .byte 22,23,24,25,26,27,28,29
    .byte 32,33,34,35,36,37,38,39
#endif

#if 0
    .byte 0,26,29,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
#endif



; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

enPassantSquare         ds 1

;---------------------------------------------------------------------------------------------------
; Move tables hold piece moves for this current ply

moveIndex       ds 1                ; points to first available 'slot' for move storage


MAX_MOVES = 128

    OPTIONAL_PAGEBREAK "MoveFrom", MAX_MOVES
    DEFINE_SUBROUTINE MoveFrom
    ds MAX_MOVES

    OPTIONAL_PAGEBREAK "MoveTo", MAX_MOVES
    DEFINE_SUBROUTINE MoveTo
    ds MAX_MOVES

    OPTIONAL_PAGEBREAK "MovePiece", MAX_MOVES
    DEFINE_SUBROUTINE MovePiece
    ds MAX_MOVES

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE InitialisePieceSquares

                lda #RAMBANK_PLY
                sta SET_BANK_RAM                    ; screwy self-referential bank-switching!

                ldx #15
.fillWP         lda WhitePiecelist,x
                sta PieceSquare+RAM_WRITE,x
                dex
                bpl .fillWP

                lda #RAMBANK_PLY+1                  ; screwy self-referential bank-switching!
                sta SET_BANK_RAM

                ldx #15
.fillBP         lda BlackPiecelist,x
                sta PieceSquare+RAM_WRITE,x
                dex
                bpl .fillBP
                rts

WhitePiecelist
    .byte 22,23,24,25,26,27,28,29
    .byte 32,33,34,35,36,37,38,39

BlackPiecelist
    .byte 82,83,84,85,86,87,88,89
    .byte 92,93,94,95,96,97,98,99


;---------------------------------------------------------------------------------------------------


    DEFINE_SUBROUTINE NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty

                ldx #-1
                stx moveIndex+RAM_WRITE             ; no valid moves
                lda #0
                sta enPassantSquare+RAM_WRITE       ; no enPassant available
                rts


;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE GenerateMovesForAllPieces

    ; TODO; create a piece list and iterate through it (black/white) for pieces to move
    ; piece square into 'currentSquare'. then...


;
;                ldx #15                 ; piece index
;                stx piecelistIndex

                inc piecelistIndex
                lda piecelistIndex
                and #15
                sta piecelistIndex

                tax

.scanPiece      lda sideToMove
                asl
                adc #RAMBANK_PLY                ; W piecelist in "PLY0" bank, and B in "PLY1"
                sta SET_BANK_RAM                ; ooh! self-switching bank

                ldx piecelistIndex
                lda PieceSquare,x
                beq .noPieceHere                ; piece deleted
                sta currentSquare

                jsr MoveForSinglePiece

.noPieceHere


                ;lda currentPly
                ;sta SET_BANK_RAM                ; switch back to "me" (done in MoveForSinglePiece)

;                dec piecelistIndex
;                bpl .scanPiece

TIMEREND
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE FixPieceList
    ; uses OVERLAY Overlay001
    ; fromX12            X12 square piece moved from
    ; toX12              X12 square piece moved to (0 to erase piece from list)

    ; It scans the piece list looking for the '__from' square and sets it to the '__to' square
    ; Eventually this will have to be more sophisticated when moves (like castling) involve
    ; more than one piece.


                ldx #15
                lda fromX12
.pieceCheck     cmp PieceSquare,x
                beq .adjustPiece
                dex
                bpl .pieceCheck
                rts

.adjustPiece    lda toX12
                sta PieceSquare+RAM_WRITE,x
                rts

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE DeletePiece

                lda fromX12
                ldy toX12

;                lda sideToMove
;                eor #128
;                asl
;                adc #RAMBANK_PLY
    lda currentPly
                sta SET_BANK_RAM

                lda toX12
                jsr DeletePiece

;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
