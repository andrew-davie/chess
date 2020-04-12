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
    NEWRAMBANK PLY                                  ; RAM bank for holding the following ROM shadow
    REPEAT MAX_PLY-1
        NEWRAMBANK .DUMMY_PLY
    REPEND

MAX_PLY_DEPTH_BANK = MAX_PLY + RAMBANK_PLY

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

    VARIABLE plyValue, 2                            ; 16-bit signed score value from alphabeta
    VARIABLE SavedEvaluation, 2                     ; THIS node's evaluation - used for reverting moves!


;---------------------------------------------------------------------------------------------------

MAX_MOVES =70

    VARIABLE MoveFrom, MAX_MOVES
    VARIABLE MoveTo, MAX_MOVES
    VARIABLE MovePiece, MAX_MOVES
    VARIABLE MoveCapture, MAX_MOVES

    VARIABLE MoveScoreLO, MAX_MOVES
    VARIABLE MoveScoreHI, MAX_MOVES
;    VARIABLE SortedMove, MAX_MOVES

;---------------------------------------------------------------------------------------------------

; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

    VARIABLE enPassantSquare, 1
    VARIABLE capturedPiece, 1
    VARIABLE originalPiece, 1
    VARIABLE secondaryPiece, 1                      ; original piece on secondary (castle, enpassant)
    VARIABLE secondarySquare, 1                     ; original square of secondary piece
    VARIABLE secondaryBlank, 1                      ; square to blank on secondary
    VARIABLE quiescentEnabled, 1                    ; all child nodes to quiesce
    VARIABLE captureMove, 1                         ; previous move was a capture

;---------------------------------------------------------------------------------------------------
; Move tables hold piece moves for this current ply

    VARIABLE moveIndex, 1                           ; points to first available 'slot' for move storage
    VARIABLE movePtr, 1
    VARIABLE bestMove, 1
    VARIABLE alpha, 2
    VARIABLE beta, 2
;    VARIABLE bestValue, 2
    VARIABLE depthLeft, 1
    VARIABLE bestScore, 2
    VARIABLE restorePiece, 1

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
    SUBROUTINE

        REFER InitialisePieceSquares
        VEND InitPieceLists

                    lda #-1
                    ;sta@RAM SquarePtr ;PieceListPtr

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

        REFER DIAGNOSTIC_checkPiences
        VAR __x, 1
        VAR __bank, 1
        VEND checkPiecesBank

    ; odd usage - switches between concurrent bank code

                ldx #15
.check          lda __bank
                sta SET_BANK_RAM
                ldy PieceSquare,x
                beq .nonehere

                stx __x

                jsr GetBoard
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

        REFER aiSpecialMoveFixup
        VEND DIAGNOSTIC_checkPiences

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
    SUBROUTINE

        REFER aiFlipBuffers
        REFER InitialiseMoveGeneration
        REFER alphaBeta
        VEND NewPlyInitialise

    ; This MUST be called at the start of a new ply
    ; It initialises the movelist to empty
    ; x must be preserved

    ; note that 'alpha' and 'beta' are set externally!!


                    lda #-1
                    sta@RAM moveIndex           ; no valid moves
                    sta@RAM bestMove

                    lda enPassantPawn               ; flag/square from last actual move made
                    sta@RAM enPassantSquare         ; used for backtracking, to reset the flag


    ; The value of the material (signed, 16-bit) is restored to the saved value at the reversion
    ; of a move. It's quicker to restore than to re-sum. So we save the current evaluation at the
    ; start of each new ply.

                    lda Evaluation
                    sta@RAM SavedEvaluation
                    lda Evaluation+1
                    sta@RAM SavedEvaluation+1

                    rts


;---------------------------------------------------------------------------------------------------

    DEF CheckMoveListFromSquare
    SUBROUTINE

        REFER IsValidMoveFromSquare
        VEND CheckMoveListFromSquare

    ; X12 in A
    ; y = -1 on return if NOT FOUND

                    ldy moveIndex
                    bmi .exit

.scan               cmp MoveFrom,y
                    beq .scanned
                    dey
                    bpl .scan
.exit               rts

.scanned            lda MovePiece,y
                    sta fromPiece
                    rts


;---------------------------------------------------------------------------------------------------

#if 0
    DEF IsSquareUnderAttack
    SUBROUTINE

        REFER Go_IsSquareUnderAttack
        REFER aiLookForCheck
        VEND IsSquareUnderAttack

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

#endif


;---------------------------------------------------------------------------------------------------

#if 0
    DEF GetKingSquare
    SUBROUTINE

        REFER SAFE_GetKingSquare
        VEND GetKingSquare

    ; Return:       a = square king is on (or -1)
    ;               x = piece type



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
#endif

;---------------------------------------------------------------------------------------------------

    DEF GetPieceGivenFromToSquares
    SUBROUTINE

        REFER GetPiece
        VEND GetPieceGivenFromToSquares

    ; returns piece in A+fromPiece
    ; or Y=-1 if not found

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
                    sta fromPiece
                    rts



;---------------------------------------------------------------------------------------------------

#if 0
    DEF CheckMoveListToSquare
    SUBROUTINE

        VEND CheckMoveListToSquare

    ; y = -1 on return if NOT FOUND

                    ldy moveIndex
                    bmi .exit
.scan               lda toX12
                    cmp MoveTo,y
                    bne .xscanned
                    lda MoveFrom,y
                    cmp fromX12
                    beq .exit
.xscanned           dey
                    bpl .scan

.exit               rts
#endif


;---------------------------------------------------------------------------------------------------
    
    DEF selectmove
    SUBROUTINE

        COMMON_VARS_ALPHABETA
        REFER aiComputerMove
        VEND selectmove

    ; RAM bank already switched in!!!

    IF DIAGNOSTICS
                    lda #0
                    sta positionCount
                    sta positionCount+1
                    sta positionCount+2

                    sta maxPly
    ENDIF

    ; both player (pos) and opponent (neg) have worst value ever!

                    lda #<INFINITY
                    sta@RAM beta
                    lda #>INFINITY
                    sta@RAM beta+1                   ; opponent tries to minimise

                    lda #<-INFINITY
                    sta@RAM alpha
                    lda #>-INFINITY
                    sta@RAM alpha+1                  ; player tries to maximise


    ; "boardValue = -alphabeta( -beta, -alpha, depthleft - 1 )"

                    sec
                    lda #0
                    sbc alpha
                    sta __alpha
                    lda #0
                    sbc alpha+1
                    sta __alpha+1                   ; = -alpha

                    sec
                    lda #0
                    sbc beta
                    sta __beta
                    lda #0
                    sbc beta+1
                    sta __beta+1                    ; = -beta (effectively unchanged) - no αβ on ply 0

                    ldx #SEARCH_DEPTH               ; depth
                    lda #0                          ; no quiescence yet
                    ldy #0                          ; no capture on last move
                    jsr alphaBeta                   ; recurse!
 
                    ldx bestMove
                    bmi .nomove
                    lda MoveTo,x
                    sta toX12
                    lda MoveFrom,x
                    sta originX12
                    sta fromX12
                    lda MovePiece,x
                    sta fromPiece

    ; get piece from board because of promotions!

                    ;ldy originX12
                    ;jsr GetBoardRAM
                    ;sta fromPiece

.nomove             rts


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
                    sta@RAM secondaryBlank
                    ldy RSquareStart,x
                    sty fromX12
                    sty originX12
                    sty@RAM secondarySquare

                    lda fromPiece
                    and #128                        ; colour bit
                    ora #ROOK                       ; preserve colour
                    sta fromPiece
                    sta@RAM secondaryPiece

                    sec
.exit               rts


;---------------------------------------------------------------------------------------------------

    DEF CastleFixupDraw
    SUBROUTINE

        REFER SpecialBody
        VEND CastleFixupDraw

    ; fixup any castling issues
    ; at this point the king has finished his two-square march
    ; based on the finish square, we determine which rook we're interacting with
    ; and generate a 'move' for the rook to position on the other side of the king


    IF CASTLING_ENABLED
                    jsr GenCastleMoveForRook
                    bcs .phase
    ENDIF
    
                    lda sideToMove
                    eor #128
                    sta sideToMove
                    rts

.phase

    ; in this siutation (castle, rook moving) we do not change sides yet!

                    PHASE AI_MoveIsSelected
                    rts



KSquare             .byte 24,28,94,98
RSquareStart        .byte 22,29,92,99
RSquareEnd          .byte 25,27,95,97


;---------------------------------------------------------------------------------------------------

    DEF SetupBanks
    SUBROUTINE

        REFER Reset
        VAR __plyBank, 1
        VEND SetupBanks

    ; SAFE

                    ldy #7
.copyRowBanks       ldx #BANK_ROM_SHADOW_OF_CHESS_BITMAP
                    jsr CopyShadowROMtoRAM
                    dey
                    bpl .copyRowBanks

    ; copy the BOARD/MOVES bank

                    ldy #RAMBANK_MOVES_RAM
                    ldx #MOVES
                    jsr CopyShadowROMtoRAM     ; this auto-initialises Board too

    ; copy the PLY banks

                    lda #MAX_PLY
                    sta __plyBank
                    ldy #RAMBANK_PLY
                    sty currentPly
.copyPlyBanks       ldx #BANK_PLY
                    jsr CopyShadowROMtoRAM
                    iny
                    dec __plyBank
                    bne .copyPlyBanks

                    rts


;---------------------------------------------------------------------------------------------------



    DEF Sort
    SUBROUTINE

        REFER aiComputerMove
        VAR __xs, 1
        VAR __swapped, 1
        VAR __pc, 1
        VEND Sort

                    lda currentPly
                    sta savedBank

                    ldx moveIndex
                    ldy moveIndex
                    dey
.scan

                    lda MoveCapture,y
                    ;and #PIECE_MASK
                    beq .next

                    lda MoveTo,x
                    pha
                    lda MoveFrom,x
                    pha
                    lda MovePiece,x
                    pha

                    lda MovePiece,y
                    sta@RAM MovePiece,x
                    pla
                    sta@RAM MovePiece,y

                    lda MoveFrom,y
                    sta@RAM MoveFrom,x
                    pla
                    sta@RAM MoveFrom,y

                    lda MoveTo,y
                    sta@RAM MoveTo,x
                    pla
                    sta@RAM MoveTo,y

                    dex

.next               dey
                    bpl .scan
                    rts


;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
