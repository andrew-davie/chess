;---------------------------------------------------------------------------------------------------
; @2 PLY.asm

; Atari 2600 Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------
; Define the RAM banks
; A "PLY" bank represents all the data required on any single ply of the search tree.
; The banks are organised sequentially, PLY_BANKS of them starting at RAMBANK_PLY
; The startup code copies the ROM shadow into each of these PLY banks, and from then on
; they act as independant switchable banks usable for data on each ply during the search.
; A ply will hold the move list for that position


    SLOT 2
    RAMBANK PLY                                  ; RAM bank for holding the following ROM shadow
    
;---------------------------------------------------------------------------------------------------

MAX_MOVES = 100          ; big is good

    VARIABLE MoveFrom, MAX_MOVES
    VARIABLE MoveTo, MAX_MOVES
    VARIABLE MovePiece, MAX_MOVES
    VARIABLE MoveCapture, MAX_MOVES


;---------------------------------------------------------------------------------------------------

; The X12 square at which a pawn CAN be taken en-passant. Normally 0.
; This is set/cleared whenever a move is made. The flag is indicated in the move description.

    VARIABLE savedEvaluation, 2                     ; THIS node's evaluation - used for reverting moves!
    VARIABLE enPassantSquare, 1
    VARIABLE capturedPiece, 1
    ;VARIABLE originalPiece, 1
    VARIABLE secondaryPiece, 1                      ; original piece on secondary (castle, enpassant)
    VARIABLE secondarySquare, 1                     ; original square of secondary piece
    VARIABLE secondaryBlank, 1                      ; square to blank on secondary
    VARIABLE moveIndex, 1                           ; points to first available 'slot' for move storage
    VARIABLE movePtr, 1
    VARIABLE bestMove, 1
    VARIABLE alpha, 2
    VARIABLE beta, 2
    VARIABLE value, 2
    VARIABLE depthLeft, 1
    VARIABLE restorePiece, 1
    VARIABLE virtualKingSquare, 2                   ; traversing squares for castle/check
    
    END_BANK


    REPEAT PLY_BANKS-1
        RAMBANK .DUMMY_PLY
        END_BANK
    REPEND


;---------------------------------------------------------------------------------------------------
; EOF
