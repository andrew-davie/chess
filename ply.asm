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

    VARIABLE MoveScoreLO, MAX_MOVES
    VARIABLE MoveScoreHI, MAX_MOVES
    VARIABLE SortedMove, MAX_MOVES

;---------------------------------------------------------------------------------------------------

; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

    VARIABLE enPassantSquare, 1
    VARIABLE capturedPiece, 1
    VARIABLE secondaryPiece, 1                      ; original piece on secondary (castle, enpassant)
    VARIABLE secondarySquare, 1                     ; original square of secondary piece
    VARIABLE secondaryBlank, 1                      ; square to blank on secondary
    
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
        REFER quiesce
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

#if 1
    DEF MoveViaListAtPly
    SUBROUTINE

        REFER aiComputerMove
        VEND MoveViaListAtPly
    
                    ldy moveIndex
                    bmi .exit                       ; no valid moves (stalemate if not in check)

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

                    lda MoveFrom,x
                    sta fromX12
                    sta originX12

                    lda MoveTo,x
                    sta toX12

                    lda MovePiece,x
                    sta fromPiece

.exit               rts
#endif

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
    
                    stx@RAM depthLeft

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

                    ldx depthLeft
                    jsr alphaBeta                   ; recurse!
 
                    ldx bestMove
                    lda MoveTo,x
                    sta toX12
                    lda MoveFrom,x
                    sta originX12
                    sta fromX12
                    lda MovePiece,x
                    sta fromPiece

                    rts


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

    jsr debug

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

#if 0
    DEF Sort
    SUBROUTINE

        VAR __big, 2
        VAR __biggest, 1
        VEND Sort

                    ldx moveIndex
                    bmi .exit

.fill               txa
                    sta@RAM SortedMove,x
                    dex
                    bpl .fill


                    ldy moveIndex
.getNext            ldx moveIndex
                    lda #<-INFINITY
                    sta __big
                    lda #>-INFINITY
                    sta __big+1

.findBig            

                    sec
                    lda MoveScoreLO,x
                    sbc __big
                    lda MoveScoreHI,x
                    sbc __big+1
                    bvc .l0
                    eor #$80
.l0                 bmi .lt            

                    lda MoveScoreLO,x
                    sta __big
                    lda MoveScoreHI,x
                    sta __big+1

                    stx __biggest

.lt                 dex
                    bpl .findBig

                    lda __biggest
                    sta@RAM SortedMove,y
                    tax


                    lda #<-INFINITY
                    sta@RAM MoveScoreLO,x
                    lda #>-INFINITY
                    sta@RAM MoveScoreHI,x



                    dey
                    bpl .getNext
.exit               rts
#endif



    DEF Sort
    SUBROUTINE

        REFER aiComputerMove
        VAR __xs, 1
        VEND Sort

                    lda currentPly
                    sta savedBank


                    ldx moveIndex
                    ldy moveIndex
                    dey
.scan               sty __xs
                    lda MoveTo,y
                    tay
                    jsr GetBoardRAM
                    ldy __xs
                    and #PIECE_MASK
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





#if 0
    DEF Sort
    SUBROUTINE

        VAR __idx, 1
        VAR __work1, 1
        VAR __work2, 2
        VAR __work3, 2
        VAR __sx, 1
        VEND Sort

        jsr debug

        ; Fill the move pointer list (in order)
        ; We want the LAST entry to be the index of the one with the BEST score
        
                    ldx moveIndex
                    stx __idx
                    bmi .exit

.fill               txa
                    sta@RAM SortedMove,x
                    dex
                    bpl .fill

        ; Now that oddball sort!

.sort               ldx __idx
                    ldy SortedMove,x
                    sty __work3
                    jmp .l2

.l1                 ldx __sx
                    dex
                    beq .l3
                    stx __sx


                    lda SortedMove,x
                    ldy __work2
                    ldx SortedMove,y        ; y = nval
                    tay                     ; x = "work2"

                    sec
                    lda MoveScoreLO,y
                    sbc MoveScoreLO,x
                    lda MoveScoreHI,y
                    sbc MoveScoreHI,x
                    bvc .lab0
                    eor #$80
.lab0               bmi .l1

                    ldx __sx

;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.

.l2                 stx __work1
                    sty __work2
                    stx __sx
                    jmp .l1

.l3                 ldy __idx
                    lda __work2
                    sta@RAM SortedMove,y
                    ldy __work1
                    lda __work3
                    sta@RAM SortedMove,y

                    dec __idx
                    bne .sort
.exit               rts
                    
;If the N flag is 1, then A (signed) < NUM (signed) and BMI will branch
;If the N flag is 0, then A (signed) >= NUM (signed) and BPL will branch
;One way to remember which is which is to remember that minus (BMI) is less than, and plus (BPL) is greater than or equal to.
#endif


#if 0
.exit


;
ZPADD  = $30            ;2 BYTE POINTER IN PAGE ZERO. SET BY CALLING PROGRAM
NVAL   = $32            ;SET BY CALLING PROGRAM
WORK1  = $33            ;3 BYTES USED AS WORKING AREA
WORK2  = $34
WORK3  = $35
        *=$6000         ;CODE ANYWHERE IN RAM OR ROM
SORT LDY NVAL           ;START OF SUBROUTINE SORT
     LDA (ZPADD),Y      ;LAST VALUE IN (WHAT IS LEFT OF) SEQUENCE TO BE SORTED
     STA WORK3          ;SAVE VALUE. WILL BE OVER-WRITTEN BY LARGEST NUMBER
     BRA L2
L1   DEY
     BEQ L3
     LDA (ZPADD),Y
     CMP WORK2
     BCC L1
L2   STY WORK1          ;INDEX OF POTENTIALLY LARGEST VALUE
     STA WORK2          ;POTENTIALLY LARGEST VALUE
     BRA L1
L3   LDY NVAL           ;WHERE THE LARGEST VALUE SHALL BE PUT
     LDA WORK2          ;THE LARGEST VALUE
     STA (ZPADD),Y      ;PUT LARGEST VALUE IN PLACE
     LDY WORK1          ;INDEX OF FREE SPACE
     LDA WORK3          ;THE OVER-WRITTEN VALUE
     STA (ZPADD),Y      ;PUT THE OVER-WRITTEN VALUE IN THE FREE SPACE
     DEC NVAL           ;END OF THE SHORTER SEQUENCE STILL LEFT
     BNE SORT           ;START WORKING WITH THE SHORTER SEQUENCE
     RTS
#endif


;---------------------------------------------------------------------------------------------------

    CHECK_HALF_BANK_SIZE "PLY -- 1K"

;---------------------------------------------------------------------------------------------------

; There is space here (1K) for use as ROM
; but NOT when the above bank is switched in as RAM, of course!




;---------------------------------------------------------------------------------------------------
; EOF
