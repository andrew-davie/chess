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

    OPTIONAL_PAGEBREAK "PieceLists", 48

SortedPieceList         ds 16           ; indexes into PieceSquare, PieceType.  NEG = no piece
PieceSquare             ds 16
PieceType               ds 16

PieceListPtr            ds 1

;---------------------------------------------------------------------------------------------------

infinity                = 32767

plyValue                ds 2            ; 16-bit signed score value
bestMove                ds 1            ; index of move (-1 = none)

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

; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

enPassantSquare         ds 1

;---------------------------------------------------------------------------------------------------
; Move tables hold piece moves for this current ply

moveIndex       ds 1                ; points to first available 'slot' for move storage


MAX_MOVES = 128

    OPTIONAL_PAGEBREAK "MoveFrom", MAX_MOVES
    DEF MoveFrom
    ds MAX_MOVES

    OPTIONAL_PAGEBREAK "MoveTo", MAX_MOVES
    DEF MoveTo
    ds MAX_MOVES

    OPTIONAL_PAGEBREAK "MovePiece", MAX_MOVES
    DEF MovePiece
    ds MAX_MOVES

;---------------------------------------------------------------------------------------------------

    DEF InitPieceLists

                lda #-1
                sta PieceListPtr+RAM_WRITE

                ldx #15
.clearLists     sta SortedPieceList+RAM_WRITE,x
                sta PieceSquare+RAM_WRITE,x
                sta PieceType+RAM_WRITE,x
                dex
                bpl .clearLists

    ; General inits that are moved out of FIXED....


                lda #%111  ; 111= quad
                sta NUSIZ0
                sta NUSIZ1              ; quad-width




                lda #%00000100
                sta CTRLPF
                lda #BACKGCOL
                sta COLUBK

                lda #0
                sta aiPhase

                rts


;---------------------------------------------------------------------------------------------------

#if ASSERTS

    DEF checkPiecesBank
    ; odd usage - switches between concurrent bank code

                ldx #15
.check          lda __bank
                sta SET_BANK_RAM
                ldy PieceSquare,x
                beq .nonehere

                stx __x

                jsr SAFE_GetPieceFromBoard
.fail           beq .fail
                cmp #-1
.fail2          beq .fail2

                ldx __x

.nonehere       dex
                bpl .check
                rts


    DEF DIAGNOSTIC_checkPieces
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

#if !TEST_POSITION
InitPieceList

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


    DEF NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty

                ldx #-1
                stx moveIndex+RAM_WRITE             ; no valid moves
                sta bestMove+RAM_WRITE

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

                lda #<(-infinity)
                sta plyValue+RAM_WRITE
                lda #>(-infinity)
                sta plyValue+RAM_WRITE+1


                lda #0
                sta piecelistIndex

                rts


;---------------------------------------------------------------------------------------------------

    DEF GenerateMovesForNextPiece

                lda piecelistIndex
                and #15
                tax

                lda sideToMove
                asl
                lda #RAMBANK_PLY                ; W piecelist in "PLY0" bank, and B in "PLY1"
                adc #0
                sta SET_BANK_RAM                ; ooh! self-switching bank

                lda PieceSquare,x
                beq .noPieceHere                ; piece deleted
                sta currentSquare

                jsr MoveForSinglePiece

.noPieceHere    inc piecelistIndex
                rts

;---------------------------------------------------------------------------------------------------

    DEF FixPieceList

    ; uses OVERLAY Overlay001
    ; fromX12            X12 square piece moved from
    ; toX12              X12 square piece moved to (0 to erase piece from list)

    ; It scans the piece list looking for the '__from' square and sets it to the '__to' square
    ; Eventually this will have to be more sophisticated when moves (like castling) involve
    ; more than one piece.

    ; TODO: this is slow and should use a pointer to pieces instead


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
    DEF DeletePiece

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

    DEF alphaBeta

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

    DEF RevertMove

    ; backtrack after a move, restoring things to the way they were








                rts


;---------------------------------------------------------------------------------------------------

    DEF MoveViaListAtPly

                lda moveIndex
                cmp #-1
                beq halted                      ; no valid moves

                tay                             ; loop count
                cpy #0
                beq muldone
                iny

                NEXT_RANDOM

                ldx #0
                lda #0
.mulx           clc
                adc rnd
                bcc .nover
                inx
.nover          dey
                bne .mulx
muldone

; fall through...
;---------------------------------------------------------------------------------------------------

    DEF PhysicallyMovePiece

.foundMove
                lda MoveFrom,x
                sta fromSquare
                sta fromX12
                lda MoveTo,x
                sta toSquare
                sta toX12


    ; If en-passant flag set (pawn doing opening double-move) then record its square as the
    ; en-passant square for the ply.

#if 0
 TODO BANK/BUGGERED AFTER
                lda currentPly
                sta SET_BANK_RAM

                ldy #0
                lda MovePiece,x
                and #ENPASSANT
                beq .notEP
                ldy toSquare
.notEP          sty enPassantSquare+RAM_WRITE

#endif


                lda MovePiece,x
                and #~ENPASSANT                 ;? unsure
                ora #MOVED                      ; piece has now been moved (flag used for castling checks)
                sta fromPiece                   ; MIGHT have castling bit set, which should be handled last


                lda fromSquare
                jsr ConvertToBase64
                sta fromSquare          ;B64

                lda toSquare
                jsr ConvertToBase64
                sta toSquare            ;B64

halted          rts

;---------------------------------------------------------------------------------------------------

    DEF ConvertToBase64
    ; uses OVERLAY "Movers"

    ; convert from 10x12 square numbering (0-119) to 8x8 square numbering (0-63)

                    sec
                    sbc #22

                    ldx #$FF
.conv64             sbc #10
                    inx
                    bcs .conv64
                    adc #10

                    sta __temp
                    txa
                    asl
                    asl
                    asl
                    ora __temp
                    tay

    ; A = column (0-7)
    ; X = row (0-7)

                    rts

;---------------------------------------------------------------------------------------------------

    DEF CheckMoveListFromSquare

    ; X12 in A
    ; y = -1 on return if NOT FOUND

                    ldy moveIndex
                    bmi .failed

.scan               cmp MoveFrom,y
                    beq .scanned
                    dey
                    bpl .scan

.scanned            lda MovePiece,y
                    sta aiPiece

.failed             rts


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


    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
