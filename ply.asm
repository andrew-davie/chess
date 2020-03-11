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
    NEWRAMBANK PLY                                  ; RAM bank for holding the following ROM shadow
    REPEAT MAX_PLY-1
        NEWRAMBANK .DUMMY_PLY
    REPEND


;---------------------------------------------------------------------------------------------------
; and now the ROM shadow - this is copied to ALL of the RAM ply banks

    NEWBANK BANK_PLY                   ; ROM SHADOW

    DEF XGetBoard
                    ldx #RAMBANK_MOVES_RAM
                    stx SET_BANK_RAM                ; now executing in other bank
                    ds 7
                    rts

;---------------------------------------------------------------------------------------------------
; The piece-lists
; ONLY the very first bank piecelist is used - all other banks switch to the first for
; piecelist usage. Note that this initialisation (below) comes from the shadow ROM/RAM copy
; but this needs to be initialised programatically on new game.

; We have TWO piecelists, in different banks
; WHITE pieces in bank BANK_PLY
; BLACK pieces in bank BANK_PLY+1


INFINITY                = 32767


    VARIABLE SortedPieceList, 16                    ; indexes into PieceSquare, etc. NEG = no piece
    VARIABLE PieceSquare, 16
    VARIABLE PieceType, 16
    VARIABLE PieceMaterialValueLO, 16
    VARIABLE PieceMaterialValueHI, 16
    VARIABLE PiecePositionValueLO, 16
    VARIABLE PiecePositionValueHI, 16
    VARIABLE PieceListPtr, 1
    VARIABLE plyValue, 2                            ; 16-bit signed score value from alphabeta
    VARIABLE bestMove, 1                            ; index of move (-1 = none)
    VARIABLE SavedEvaluation, 2                     ; THIS node's evaluation - used for reverting moves!


;---------------------------------------------------------------------------------------------------

MAX_MOVES = 100

    VARIABLE MoveFrom, MAX_MOVES
    VARIABLE MoveTo, MAX_MOVES
    VARIABLE MovePiece, MAX_MOVES


;---------------------------------------------------------------------------------------------------

; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

    VARIABLE enPassantSquare, 1


;---------------------------------------------------------------------------------------------------
; Move tables hold piece moves for this current ply

    VARIABLE moveIndex, 1                           ; points to first available 'slot' for move storage


;---------------------------------------------------------------------------------------------------


#if 0
; reverting a move
; from/to/piece/toOriginal
; castling   affects 4 squares (2xfrom/to each with original piece)
; en-passant

from/to/piece


from = piece
to = originalPiece
from2 = piece2
to2 = originalPiece2



so, normal move (N)

B1 = knight
C3 = blank
null/null

pawn promot with capture
A7 = WP
B8 = BLACK_ROOK


castle
E1=king
G1=blank
H1=rook
F1=blank


en-passant
B4=P
A3=blank
A4=P
A3=blank

FROM
TO
CAPTURED_PIECE
ORIG_PIECE
FROM2
TO2
PIECE2

board[FROM] = ORIG_PIECE
board[TO] = CAPTURED_PIECE

value = -new_piece + orig_piece - captured_piece


#endif



;---------------------------------------------------------------------------------------------------

    DEF InitPieceLists

                    lda #-1
                    sta PieceListPtr+RAM_WRITE

                    ldx #15
                    lda #0
.clearLists         sta SortedPieceList+RAM_WRITE,x
                    sta PieceSquare+RAM_WRITE,x
                    sta PieceType+RAM_WRITE,x
                    dex
                    bpl .clearLists


    ; TODO: move the following as they're called 2x due to double-call of InitPiecLists

                    sta Evaluation
                    sta Evaluation+1                ; tracks CURRENT value of everything (signed 16-bit)


    ; General inits that are moved out of FIXED....

                    lda #%111  ; 111= quad
                    sta NUSIZ0
                    sta NUSIZ1              ; quad-width

                    lda #%00000100
                    sta CTRLPF
                    lda #BACKGCOL
                    sta COLUBK

                    PHASE AI_StartClearBoard
                    rts


;---------------------------------------------------------------------------------------------------

#if ASSERTS

    DEF checkPiecesBank
    SUBROUTINE

        VAR __x, 1
        VAR __bank, 1

    ; odd usage - switches between concurrent bank code

                ldx #15
.check          lda __bank
                sta SET_BANK_RAM
                ldy PieceSquare,x
                beq .nonehere

                stx __x

                jsr XGetBoard
.fail           beq .fail
                cmp #-1
.fail2          beq .fail2

                ldx __x

.nonehere       dex
                bpl .check
                rts

#endif


;---------------------------------------------------------------------------------------------------

#if ASSERTS

    DEF DIAGNOSTIC_checkPieces
    SUBROUTINE

    ; SAFE call
    ; DIAGNOSTIC ONLY
    ; Scan the piecelist and the board square it points to and make sure non blank, non -1

                    lda #RAMBANK_PLY
                    sta __bank
                    jsr checkPiecesBank
                    inc __bank
                    jsr checkPiecesBank
                    rts

#endif


;---------------------------------------------------------------------------------------------------

InitPieceList

    include "setup_board.asm"


;---------------------------------------------------------------------------------------------------

    DEF NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty

                    ldx #-1
                    stx moveIndex+RAM_WRITE         ; no valid moves
                    sta bestMove+RAM_WRITE

                    lda enPassantPawn               ; flag/square from last actual move made
                    sta enPassantSquare+RAM_WRITE   ; used for backtracking, to reset the flag

    ; The evaluation of the current position is a signed 16-bit number
    ; +ve is good for the current side.
    ; This is used during the alpha-beta search for finding best position
    ; Note, this is not the same as the 'Evaluation' which is the current value at ply -- it is the
    ; alphabeta best/worst value of the node!!

                    lda #<(-INFINITY)
                    sta plyValue+RAM_WRITE
                    lda #>(-INFINITY)
                    sta plyValue+RAM_WRITE+1

    ; The value of the material (signed, 16-bit) is restored to the saved value at the reversion
    ; of a move. It's quicker to restore than to re-sum. So we save the current evaluation at the
    ; start of each new ply.

                    lda Evaluation
                    sta SavedEvaluation+RAM_WRITE
                    lda Evaluation+1
                    sta SavedEvaluation+RAM_WRITE+1

                    lda #0
                    sta piecelistIndex                  ; move traversing

                    rts


;---------------------------------------------------------------------------------------------------

    DEF GenerateMovesForNextPiece

                    lda piecelistIndex
                    and #15
                    tax

                    lda sideToMove
                    asl
                    lda #RAMBANK_PLY            ; W piecelist in "PLY0" bank, and B in "PLY1"
                    adc #0
                    sta SET_BANK_RAM            ; ooh! self-switching bank

                    lda PieceSquare,x
                    beq .noPieceHere            ; piece deleted
                    sta currentSquare

                    ;lda enPassantSquare        ; saved from previous side's move...
                    ;sta enPassantPawn          ; used for move generation

                    jsr MoveForSinglePiece

.noPieceHere        inc piecelistIndex

                    lda piecelistIndex
                    and #15
                    cmp #0
                    beq .stop

                    lda INTIM
                    cmp #22
                    bcs GenerateMovesForNextPiece


.stop               rts


;---------------------------------------------------------------------------------------------------

    DEF GetMaterialValue
    SUBROUTINE

        VAR __material, 2

#if 0
                    lda #0
                    sta __material
                    sta __material+1

                    ldx #15
.sum                lda PieceSquare,x
                    beq .dead

                    clc
                    lda __material
                    adc PieceMaterialValueLO,x
                    sta __material
                    lda __material+1
                    adc PieceMaterialValueHI,x
                    sta __material+1

.dead               dex
                    bpl .sum
#endif
                    rts


;---------------------------------------------------------------------------------------------------

    DEF FixPieceList
    SUBROUTINE

    ; fromX12            X12 square piece moved from
    ; toX12              X12 square piece moved to (0 to erase piece from list)

    ; It scans the piece list looking for the '__from' square and sets it to the '__to' square
    ; Eventually this will have to be more sophisticated when moves (like castling) involve
    ; more than one piece.

    ; TODO: this is slow and should use a pointer to pieces instead


                    ldx #15
                    lda originX12
.pieceCheck         cmp PieceSquare,x
                    beq .adjustPiece
                    dex
                    bpl .pieceCheck
                    rts

.adjustPiece        lda toX12
                    sta PieceSquare+RAM_WRITE,x
                    rts


;---------------------------------------------------------------------------------------------------

    DEF alphaBeta
    SUBROUTINE


#if 0

1. create movelist
2. init score







#endif




                    rts

                    inc currentPly
                    lda currentPly

                    cmp #MAX_PLY+RAMBANK_PLY
                    beq .bottomOut                  ; at a leaf node of the search?
                    sta SET_BANK_RAM                ; self-referential weirdness!

                    lda sideToMove
                    eor #128
                    sta sideToMove

                    jsr NewPlyInitialise

                    lda currentPly
                    sta SET_BANK_RAM

                    lda #0
                    sta piecelistIndex
iterPieces          jsr GenerateMovesForNextPiece
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
                    sta SET_BANK_RAM                ; self-referential weirdness!

                    rts

;---------------------------------------------------------------------------------------------------

    DEF RevertMove
    SUBROUTINE

    ; backtrack after a move, restoring things to the way they were


    ; piecelist
        ; piece1, piece2
    ; board
    ; enpassantpawn
    ; materialvalue
    ; positionvalue
    ; score?


    ; restore the board evaluation to what it was at the start of this ply

                    lda SavedEvaluation
                    sta Evaluation
                    lda SavedEvaluation+1
                    sta Evaluation+1

                    rts


;---------------------------------------------------------------------------------------------------

    DEF MoveViaListAtPly
    SUBROUTINE

                    ldy moveIndex
                    bmi halted                      ; no valid moves (stalemate if not in check)

                    NEXT_RANDOM

    ; int(random * # moves) --> a random move #

                    lda #0
                    tax                             ; selected move
                    clc
.mulxcc             adc rnd
                    bcc .mulx
                    clc
                    inx
.mulx               dey
                    bpl .mulxcc

    IF ASSERTS
    ; Catch illgal move/index
                    cpx moveIndex
                    beq .ok
.whoops             bcs .whoops
.ok
    ENDIF


; fall through...
;---------------------------------------------------------------------------------------------------

    ;DEF PhysicallyMovePiece

.foundMove
                    lda MoveFrom,x
                    sta fromX12
                    sta originX12

                    lda MoveTo,x
                    sta toX12

                    lda MovePiece,x
                    ;ora #FLAG_MOVED                ; prevents usage in castling (for K/R)
                    sta fromPiece                   ; MIGHT have castling bit set, which should be handled last

halted              rts


;---------------------------------------------------------------------------------------------------

    DEF CheckMoveListFromSquare
    SUBROUTINE

    ; X12 in A
    ; y = -1 on return if NOT FOUND

                    ldy moveIndex
                    bmi .failed

.scan               cmp MoveFrom,y
                    beq .scanned
                    dey
                    bpl .scan

.scanned            lda MovePiece,y
                    ;and #PIECE_MASK
                    sta aiPiece

.failed             rts


;---------------------------------------------------------------------------------------------------

    DEF IsSquareUnderAttack
    SUBROUTINE

    ; Scan the movelist to find if given square is under attack

    ; Pass:         A = X12 square to check
    ; Return:       CC = no

                    ldy moveIndex
                    bmi .exit
.scan               cmp MoveTo,y
                    beq .found                      ; YES!
                    dey
                    bpl .scan

.exit               clc
.found              rts


;---------------------------------------------------------------------------------------------------

    DEF GetKingSquare
    SUBROUTINE

    ; Return:       a = square king is on (or -1)

                    ldy PieceListPtr
                    bmi .exit                       ; no pieces?!
.find               lda PieceType,y
                    and #PIECE_MASK
                    cmp #KING
                    beq .found
                    dey
                    bpl .find

.exit               lda #-1                         ; not found/no king square
                    rts

.found              lda PieceSquare,y
                    ldx PieceType,y
                    rts


;---------------------------------------------------------------------------------------------------

    DEF GetPieceGivenFromToSquares
    SUBROUTINE

    ; We need to get the piece from the movelist because it contains flags (e.g., castling) about
    ; the move. We need to do from/to checks because moves can have multiple origin/desinations.
    ; This fixes the move with/without castle flag

                    ldy moveIndex
                    bmi .fail               ; shouldn't happen
.scan               lda fromX12
                    cmp MoveFrom,y
                    bne .next
                    lda toX12
                    cmp MoveTo,y
                    beq .found
.next               dey
                    bpl .scan
.fail               rts

.found              lda MovePiece,y
                    ;and #PIECE_MASK        castling fails if enabled
                    sta aiPiece
                    rts



;---------------------------------------------------------------------------------------------------

    DEF CheckMoveListToSquare
    SUBROUTINE

    ; X12 in A
    ; y = -1 on return if NOT FOUND

                    ldy moveIndex
                    bmi .sout
.scan               cmp MoveTo,y
                    bne .xscanned

                    pha
                    lda MoveFrom,y
                    cmp aiFromSquareX12
                    beq .scanned
                    pla

.xscanned           dey
                    bpl .scan
                    pha

.scanned            pla
.sout               rts


;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
