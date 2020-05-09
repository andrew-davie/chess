; Chess
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com


;---------------------------------------------------------------------------------------------------
;#########################################  FIXED BANK  ############################################
;---------------------------------------------------------------------------------------------------

ORIGIN              SET FIXED_BANK

                    NEWBANK THE_FIXED_BANK
                    RORG $f800

;---------------------------------------------------------------------------------------------------

    DEF Reset
    SUBROUTINE

        VEND Reset

                    ldx #$FF
                    txs

                    JSROM_SAFE cartInit

                    ;JSROM TitleScreen

                    ;JSROM ShutYourMouth

    ; Patch the final row's "loop" to a RTS

                    ldx #7
                    stx SET_BANK_RAM
                    lda #$60                        ; "rts"
                    sta@RAM SELFMOD_RTS_ON_LAST_ROW

                    jsr InitialisePieceSquares


                    ;RESYNC
.StartFrame


    ; START OF FRAME

                    lda #%1110                      ; VSYNC ON
.loopVSync3         sta WSYNC
                    sta VSYNC
                    lsr
                    bne .loopVSync3                 ; branch until VYSNC has been reset

                    sta VBLANK

                    ldy #TIME_PART_1
                    sty TIM64T

    ; LOTS OF PROCESSING TIME - USE IT

                    jsr AiStateMachine


;xx2 lda INTIM
; beq xx2


    IF ASSERTS
; Catch timer expired already
;                    bit TIMINT
;.whoops             bmi .whoops
    ENDIF


.wait               bit TIMINT
                    bpl .wait


    ; START OF VISIBLE SCANLINES


                    JSROM longD

                    stx SET_BANK_RAM
                    jsr DrawRow                     ; draw the ENTIRE visible screen!

                    JSROM tidySc

                    jsr AiStateMachine

    lda INTIM
    cmp #20
    bcc .notnow                    

                    JSROM GameSpeak
                    JSROM PositionSprites


    ; "draw" sprite shapes into row banks

                    ldx #7
zapem               stx SET_BANK_RAM
                    jsr WriteBlank
                    dex
                    bpl zapem

                    jsr WriteCursor
.notnow

;    lda aiState
;    beq Waitforit
;    cmp #22
;    bcc Waitforit
;xx3 bit TIMINT
; bmi xx3

.waitTime           bit TIMINT
                    bpl .waitTime

                    jmp .StartFrame


_rts                rts


;---------------------------------------------------------------------------------------------------

    DEF AiStateMachine
    SUBROUTINE

        REFER Reset
        VEND AiStateMachine

                    JSROM AiSetupVectors
                    sta SET_BANK
                    jmp (__ptr)                 ; TODO: OR branch back to squeeze cycles


;---------------------------------------------------------------------------------------------------

    DEF aiDrawEntireBoard
    SUBROUTINE

        REFER AiStateMachine
        VEND aiDrawEntireBoard


                    lda INTIM
                    cmp #SPEEDOF_COPYSINGLEPIECE+4
                    bcc .exit

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

                    jsr CopySinglePiece

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

    DEF aiGenerateMoves
    SUBROUTINE

        REFER AiStateMachine
        VEND aiGenerateMoves
    
    ; Player comes here at the start of making a move
    ; This generates a valid movelist by calling 'negaMax' (removing illegal moves)

                    lda toX12
                    sta squareToDraw                    ; for showing move (display square)

                    ldx sideToMove
                    bpl .player


.computer           PHASE AI_ComputerMove               ; computer select move
                    rts

                    
.player             PHASE AI_StartMoveGen
                    rts


;---------------------------------------------------------------------------------------------------

    DEF aiStepMoveGen
    SUBROUTINE

        REFER AiStateMachine
        VEND aiStepMoveGen

                    lda originX12                       ; location of cursor (show move)
                    sta cursorX12
                    PHASE AI_BeginSelectMovePhase
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

MoveReturn          ldx currentSquare

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
                    
                    jmp handleIt


.exit
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

    DEF AdjustMaterialPositionalValue
    SUBROUTINE

    ; A move is about to be made, so  adjust material and positional values based on from/to and
    ; capture.

    ; First, nominate referencing subroutines so that local variables can be adjusted properly

        REFER negaMax
        REFER MakeMove
        REFER aiMoveIsSelected
        VAR __originalPiece, 1
        VAR __capturedPiece, 1
        VEND AdjustMaterialPositionalValue

    ; fromPiece     piece doing the move (promoted type)
    ; fromX12       current square
    ; originX12     starting square
    ; toX12         ending square


    ; get the piece types from the board

                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    ldy originX12
                    lda Board,y
                    sta __originalPiece
                    ldy toX12
                    lda Board,y
                    sta __capturedPiece

    ; {
    ;   adjust the positional value  (originX12 --> fromX12)

                    lda #RAMBANK_BANK_EVAL ;BANK_AddPiecePositionValue
                    sta SET_BANK_RAM 


                    ;ldy toX12
                    lda fromPiece
                    jsr AddPiecePositionValue       ; add pos value for new position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same1                      ; unchanged, so skip

                    lda fromPiece                   ; new piece
                    ;and #PIECE_MASK
                    ;tay
                    jsr AddPieceMaterialValue

.same1

    ; and now the 'subtracts'

                    NEGEVAL

                    ldy originX12
                    lda __originalPiece
                    jsr AddPiecePositionValue       ; remove pos value for original position


                    lda __originalPiece
                    eor fromPiece                   ; the new piece
                    and #PIECE_MASK
                    beq .same2                      ; unchanged, so skip

                    lda __originalPiece
                    ;and #PIECE_MASK
                    ;tay
                    jsr AddPieceMaterialValue       ; remove material for original type
.same2

                    NEGEVAL

    ; If there's a capture, we adjust the material value    

;                    lda __capturedPiece
;                    eor __originalPiece
;                    bpl .noCapture                  ; special-case capture rook castling onto king


                    lda __capturedPiece
                    and #PIECE_MASK
                    beq .noCapture
                    ;tay
                    jsr AddPieceMaterialValue       ; -other colour = + my colour!
.noCapture

    ; }
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF debug
    SUBROUTINE

    ; Use this to trap breakpoints in "unknown" banks. Just "jsr debug" from wherever you want
    ; to catch the code, and put a breakpoint here instead. Then step, and you're at the place
    ; you wanted to see, without knowing the bank.

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

    include "Handler_PAWN.asm"
    include "Handler_KNIGHT.asm"

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

    DEF InitialisePieceSquares
    SUBROUTINE

        REFER Reset
        VAR __initPiece, 1
        VAR __initSquare, 1
        VAR __initListPtr, 1
        VEND InitialisePieceSquares

                    JSROM InitPieceLists

                    ldx #0
                    stx enPassantPawn               ; no en-passant
                    ;stx maxPly

    ; Now setup the board/piecelists

.fillPieceLists
                    lda #BANK_InitPieceList
                    sta SET_BANK

                    lda InitPieceList,x             ; colour/-1
                    beq .exit
                    sta __originalPiece             ; type

                    ldy InitPieceList+1,x           ; square
                    sty __initSquare
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda __originalPiece
                    sta@RAM Board,y

                    bpl .white
                    NEGEVAL
.white

    ; Add the material value of the piece to the evaluation

                    lda __originalPiece
                    ;and #PIECE_MASK
                    ;tay

;                    ldy #BANK_AddPieceMaterialValue
;                    sty SET_BANK
                    lda #RAMBANK_BANK_EVAL ;BANK_AddPiecePositionValue
                    sta SET_BANK_RAM 
                    jsr AddPieceMaterialValue

                    stx __initListPtr

    ; add the positional value of the piece to the evaluation 

                    ldy __initSquare
                    lda __originalPiece

                    ldx #BANK_AddPiecePositionValue
                    stx SET_BANK
                    jsr AddPiecePositionValue



                    lda __originalPiece             ; type/colour
                    bpl .white2
                    NEGEVAL
.white2

                    ldx __initListPtr
                    inx
                    inx
                    bpl .fillPieceLists

.exit

                    jmp ListPlayerMoves

;---------------------------------------------------------------------------------------------------

    DEF GetValid
                    lda #RAMBANK_BOARD
                    sta SET_BANK_RAM
                    lda ValidSquare,y
                    ldy savedBank
                    sty SET_BANK
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

    DEF PutBoard
                    ldx #RAMBANK_BOARD
                    stx SET_BANK_RAM
                    sta@RAM Board,y             ; and what's actually moving there
                    ldx savedBank
                    stx SET_BANK
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


    DEF CopyShadowROMtoRAM
    SUBROUTINE

        REFER SetupBanks
        VAR __destinationBank, 1
        VAR __sourceBank, 1
        VEND CopyShadowROMtoRAM

    ; Copy a whole 1K ROM SHADOW into a destination RAM 1K bank
    ; used to setup callable RAM code from ROM templates

    ; x = source ROM bank
    ; y = destination RAM bank (preserved)

                    stx __sourceBank

                    ldx #0
.copyPage           lda __sourceBank
                    sta SET_BANK

                    lda $F000,x
                    pha
                    lda $F100,x
                    pha
                    lda $F200,x
                    pha
                    lda $F300,x

                    sty SET_BANK_RAM

                    sta@RAM $F300,x
                    pla
                    sta@RAM $F200,x
                    pla
                    sta@RAM $F100,x
                    pla
                    sta@RAM $F000,x

                    dex
                    bne .copyPage

                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF CopySinglePiece
    SUBROUTINE

        VEND CopySinglePiece


        REFER aiDrawEntireBoard
        REFER aiSpecialMoveFixup
        REFER aiWriteStartPieceBlank
        REFER aiDrawPart2
        REFER aiMarchB
        REFER aiFinalFlash
        REFER UNSAFE_showMoveCaptures
        REFER aiMarchToTargetA
        REFER aiMarchB2
        REFER aiMarchToTargetB
        REFER aiSelectDestinationSquare
        REFER aiPromotePawnStart
        REFER aiChoosePromotePiece
        VEND CopySinglePiece

    ; WARNING: CANNOT USE VAR/OVERLAY IN ANY ROUTINE CALLING THIS!!
    ; ALSO CAN'T USE IN THIS ROUTINE
    ; This routine will STOMP on those vars due to __pieceShapeBuffer occupying whole overlay
    ; @2150 max
    ; = 33 TIM64T

                    JSROM CopySetup

    DEF InterceptMarkerCopy
    SUBROUTINE


    ; Copy a piece shape (3 PF bytes wide x 24 lines) to the RAM buffer
    ; y = piece index

                    lda #BANK_PIECE_VECTOR_BANK
                    sta SET_BANK

                    lda PIECE_VECTOR_LO,y
                    sta __ptr
                    lda PIECE_VECTOR_HI,y
                    sta __ptr+1
                    lda PIECE_VECTOR_BANK,y
                    sta SET_BANK

                    ldy #PIECE_SHAPE_SIZE-1
.copy               lda (__ptr),y
                    sta __pieceShapeBuffer,y
                    dey
                    bpl .copy

                    lda squareToDraw
                    sec
                    ldx #10
.sub10              sbc #10
                    dex
                    bcs .sub10

                    stx SET_BANK_RAM                ; row

                    adc #8
                    cmp #4                          ; CS = right side of screen

                    jsr CopyPieceToRowBitmap

                    lda savedBank
                    sta SET_BANK
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

    DEF markerDraw
    SUBROUTINE

        REFER showMoveOptions
        VEND markerDraw

                    ldx #INDEX_WHITE_MARKER_on_WHITE_SQUARE_0
                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF showPromoteOptions
    SUBROUTINE

        REFER aiRollPromotionPiece
        REFER aiChoosePromotePiece
        VEND showPromoteOptions

    ; X = character shape # (?/N/B/R/Q)

                    ldy toX12
                    sty squareToDraw

                    JSROM CopySetupForMarker
                    jmp InterceptMarkerCopy


;---------------------------------------------------------------------------------------------------

    DEF SAFE_BackupBitmaps
    SUBROUTINE

        VEND SAFE_BackupBitmaps

                    sty SET_BANK_RAM
                    jsr SaveBitmap
                    lda savedBank
                    sta SET_BANK
                    rts


;---------------------------------------------------------------------------------------------------

    DEF SAFE_showMoveCaptures
    SUBROUTINE

        VEND SAFE_showMoveCaptures

                    JSROM UNSAFE_showMoveCaptures
                    lda savedBank
                    sta SET_BANK
                    rts


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

    DEF GetP_MovePiece
    SUBROUTINE

                    lda #RAMBANK_PLY+1
                    sta SET_BANK_RAM
                    ldy savedBank
                    lda@PLY MovePiece,x
                    sty SET_BANK
                    rts


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
                    JSROM EnPassantCheck
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

;function negaMax(node, depth, α, β, color) is
;    if depth = 0 or node is a terminal node then
;        return color × the heuristic value of node

;    childNodes := generateMoves(node)
;    childNodes := orderMoves(childNodes)
;    value := −∞
;    foreach child in childNodes do
;        value := max(value, −negaMax(child, depth − 1, −β, −α, −color))
;        α := max(α, value)
;        if α ≥ β then
;            break (* cut-off *)
;    return value
;(* Initial call for Player A's root node *)
;negaMax(rootNode, depth, −∞, +∞, 1)


    SUBROUTINE

.doQ                lda #-1
                    sta __quiesceCapOnly
                    jsr quiesce
                    inc __quiesceCapOnly
                    rts


.exit               lda@PLY value
                    sta __negaMax
                    lda@PLY value+1
                    sta __negaMax+1
                    rts
                    

.terminal           cmp #0                          ; captured piece
                    bne .doQ                        ; last move was capture, so quiesce


    IF 0
    ; king moves will also quiesce
    ; theory is - we need to see if it was an illegal move

                    lda fromPiece
                    and #PIECE_MASK
                    cmp #KING
                    beq .doQ
    ENDIF
                        
                    lda Evaluation
                    sta __negaMax
                    lda Evaluation+1
                    sta __negaMax+1

.inCheck2           rts



    DEF negaMax

    ; PARAMS depth-1, -beta, -alpha
    ; pased through temporary variables (__alpha, __beta) and X reg

    ; pass...
    ; x = depthleft
    ; a = captured piece
    ; SET_BANK_RAM      --> current ply
    ; __alpha[2] = param alpha
    ; __beta[2] = param beta


        COMMON_VARS_ALPHABETA
        REFER selectmove
        VEND negaMax

                    pha

                    JSROM ThinkBar
                    lda currentPly
                    sta SET_BANK_RAM

                    pla
                    dex
                    bmi .terminal
                    stx@PLY depthLeft


    ; Allow the player to force computer to select a move. Press the SELECT switch
    ; This may have issues if no move has been selected yet. Still... if you wanna cheat....

                    lda SWCHB
                    and #2
                    beq .exit                       ; SELECT abort
                    sta COLUPF                      ; grey thinkbars

                    lda __alpha
                    sta@PLY alpha
                    lda __alpha+1
                    sta@PLY alpha+1

                    lda __beta
                    sta@PLY beta
                    lda __beta+1
                    sta@PLY beta+1


    IF 1
                    lda Evaluation
                    adc randomness
                    sta Evaluation
                    bcc .evh
                    inc Evaluation+1
.evh
    ENDIF

                    jsr GenerateAllMoves
                    lda flagCheck
                    bne .inCheck2                           ; OTHER guy in check

    IF 1
                    lda@PLY moveIndex
                    bmi .none
                    lsr
                    lsr
                    lsr
                    lsr
                    lsr
                    adc Evaluation
                    sta Evaluation
                    lda Evaluation+1
                    adc #0
                    sta Evaluation+1
.none
    ENDIF


                    lda #<-INFINITY
                    sta@PLY value
                    lda #>-INFINITY
                    sta@PLY value+1

                    ldx@PLY moveIndex
                    bpl .forChild
                    jmp .exit
                    
.forChild           stx@PLY movePtr

                    jsr MakeMove



    ;        value := max(value, −negaMax(child, depth − 1, −β, −α, −color))

    ; PARAMS depth-1, -beta, -alpha
    ; pased through temporary variables (__alpha, __beta) and X reg

                    sec
                    lda #0
                    sbc@PLY beta
                    sta __alpha
                    lda #0
                    sbc@PLY beta+1
                    sta __alpha+1

                    sec
                    lda #0
                    sbc@PLY alpha
                    sta __beta
                    lda #0
                    sbc@PLY alpha+1
                    sta __beta+1


                    ldx@PLY depthLeft
                    lda@PLY capturedPiece

                    inc currentPly
                    ldy currentPly
                    sty SET_BANK_RAM                ; self-switch
                    
                    jsr negaMax

                    dec currentPly
                    lda currentPly
                    sta SET_BANK_RAM

                    jsr unmakeMove

                    sec
                    lda #0
                    sbc __negaMax
                    sta __negaMax
                    lda #0
                    sbc __negaMax+1
                    sta __negaMax+1                 ; -negaMax(...)

                    lda flagCheck
                    beq .notCheck
                    
    ; at this point we've determined that the move was illegal, because the next ply detected
    ; a king capture. So, the move should be totally discounted

                    lda #0
                    sta flagCheck                   ; so we don't retrigger in future - it's been handled!
                    beq .nextMove                   ; unconditional - move is not considered!

.notCheck           sec
                    lda@PLY value
                    sbc __negaMax
                    lda@PLY value+1
                    sbc __negaMax+1
                    bvc .lab0
                    eor #$80
.lab0               bpl .lt0                        ; branch if value >= negaMax

    ; so, negaMax > value!

                    lda __negaMax
                    sta@PLY value
                    lda __negaMax+1
                    sta@PLY value+1                 ; max(value, -negaMax)

                    lda@PLY movePtr
                    sta@PLY bestMove
.lt0

;        α := max(α, value)

                    sec
                    lda@PLY value
                    sbc@PLY alpha
                    lda@PLY value+1
                    sbc@PLY alpha+1
                    bvc .lab1
                    eor #$80
.lab1               bmi .lt1                        ; value < alpha

                    lda@PLY value
                    sta@PLY alpha
                    lda@PLY value+1
                    sta@PLY alpha+1                 ; alpha = max(alpha, value)

.lt1

;        if α ≥ β then
;            break (* cut-off *)

                    sec
                    lda@PLY alpha
                    sbc@PLY beta
                    lda@PLY alpha+1
                    sbc@PLY beta+1
                    bvc .lab2
                    eor #$80
.lab2               bpl .retrn                      ; alpha >= beta


.nextMove           ldx@PLY movePtr
.nextX              dex
                    bmi .retrn
                    jmp .forChild

.retrn              jmp .exit


;---------------------------------------------------------------------------------------------------

    ECHO "FREE BYTES IN FIXED BANK = ", $FFFC - *

;---------------------------------------------------------------------------------------------------
    ; The reset vectors
    ; these must live in the fixed bank (last 2K of any ROM image in "3E" scheme)

    SEG InterruptVectors
    ORG FIXED_BANK + $7FC
    RORG $7ffC

                    .word Reset                     ; RESET
                    .word Reset                     ; IRQ        (not used)

;---------------------------------------------------------------------------------------------------
; EOF
