; Copyright (C)2020 Andrew Davie
; andrew@taswegian.com

;---------------------------------------------------------------------------------------------------
; Define the RAM banks
; A "PLY" bank represents all the data required on any single ply of the search tree.
; The banks are organised sequentially, MAX_PLY of them starting at RAMBANK_PLY
; The startup code copies the ROM shadow into each of these PLY banks, and from then on
; they act as independant switchable banks usable for data on each ply during the search.
; A ply will hold the move list for that position


MAX_PLY  = 6
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
    ds 16



;---------------------------------------------------------------------------------------------------

oo                     = 32767         ; "infinity"
plyValue               ds 2            ; signed value of the current position


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

#if !TEST_POSITION
WhitePiecelist
    .byte 22,23,24,25,26,27,28,29
    .byte 32,33,34,35,36,37,38,39

BlackPiecelist
    .byte 82,83,84,85,86,87,88,89
    .byte 92,93,94,95,96,97,98,99
#endif

#if TEST_POSITION
WhitePiecelist
    .byte 65,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0

BlackPiecelist
    .byte 66,0,0,0,0,0,0,0
    .byte 0,0,0,0,0,0,0,0
#endif



;---------------------------------------------------------------------------------------------------


    DEFINE_SUBROUTINE NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty

                ldx #-1
                stx moveIndex+RAM_WRITE             ; no valid moves
#if !TEST_POSITION
                lda #0
#endif

#if TEST_POSITION
                lda #66
#endif

                sta enPassantSquare+RAM_WRITE       ; no enPassant available


    ; The evaluation of the current position is a signed 16-bit number
    ; +ve is good for the current side.
    ; This is used during the alpha-beta search for finding best position


                lda #<oo
                sta plyValue
                lda #>oo
                sta plyValue+1


                rts


;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE GenerateMovesForNextPiece

                lda piecelistIndex
                and #15
                tax

                lda sideToMove
                asl
                adc #RAMBANK_PLY                ; W piecelist in "PLY0" bank, and B in "PLY1"
                sta SET_BANK_RAM                ; ooh! self-switching bank

                lda PieceSquare,x
                beq .noPieceHere                ; piece deleted
                sta currentSquare

                jsr MoveForSinglePiece

.noPieceHere    inc piecelistIndex
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

#if 0
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
#endif

;---------------------------------------------------------------------------------------------------

    DEFINE_SUBROUTINE alphaBeta

 rts
                inc currentPly
                lda currentPly

                cmp #MAX_PLY+RAMBANK_PLY
                beq .bottomOut                      ; at a leaf node of the search?
                sta SET_BANK_RAM                    ; self-referential weirdness!

                lda sideToMove
                eor #128
                sta sideToMove

                jsr NewPlyInitialise

                lda currentPly
                sta SET_BANK_RAM

                lda #0
                sta piecelistIndex
iterPieces      jsr GenerateMovesForNextPiece
                lda piecelistIndex
                cmp #15
                bne iterPieces

        ; Perform a recursive search
        ; simulate alpha-beta cull to just 7 moves per node

    REPEAT 7
            ;jsr PhysicallyMovePiece
            ;jsr FinaliseMove
            jsr alphaBeta
    REPEND

.bottomOut

        ; TODO: evaluate board position
        ; reverse move to previous position
        ; check the results, update scores and move pointers
        ; and return vars to expected

                lda sideToMove
                eor #128
                sta sideToMove

                dec currentPly
                lda currentPly
                sta SET_BANK_RAM                    ; self-referential weirdness!

                rts



;---------------------------------------------------------------------------------------------------


    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
