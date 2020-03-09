    NEWBANK RECON

;---------------------------------------------------------------------------------------------------

    DEF UNSAFE_showMoveCaptures
    SUBROUTINE

        VAR __x, 1
        VAR __fromSquare, 1
        VAR __toSquare, 1

    ; place a marker on the board for any square matching the piece
    ; EXCEPT for squares which are occupied (we'll flash those later)
    ; x = movelist item # being checked

                    lda savedBank
                    pha

                    lda #BANK_UNSAFE_showMoveCaptures
                    sta savedBank


.next               ldx aiMoveIndex
                    bmi .skip                       ; no moves in list

                    dec aiMoveIndex

                    jsr GetMoveFrom
                    cmp aiFromSquareX12
                    bne .next
                    sta __fromSquare

                    jsr GetMoveTo
                    sta __toSquare

                    tay
                    jsr GetBoard
                    and #PIECE_MASK
                    beq .next
                    cmp #BP+1
                    bcs .legit

    ; if the "moveto" square appears more than once... urk
    ; then we skip the next three moves (assuming they're promotions)

    #if 0
.sk                 dex
                    bmi .legit

                    jsr GetMoveTo
                    cmp __toSquare
                    bne .legit

                    dec aiMoveIndex
                    dec aiMoveIndex
                    dec aiMoveIndex
    #endif

.legit

        TIMECHECK COPYSINGLEPIECE, skip000

                    ldy __toSquare
                    lda X12B64_00,y                 ; convert from X12 numbering to B64
                    sta drawPieceNumber

                    jsr SAFE_CopySinglePiece

.skip
skip000
                    pla
                    sta savedBank

                    rts


    ; Use a local copy of the conversion table as it saves fixed bank bytes
    ALLOCATE X12B64_00, 100
    X12B64TABLE


;---------------------------------------------------------------------------------------------------

    DEF RECON_MarchToTargetA


        VAR __fromRow, 1

    ; Start marching towards destination

                    ;lda drawDelay
                    ;beq .progress
                    ;dec drawDelay
                    ;rts
.progress

                    lda fromSquare
                    cmp toSquare
                    beq .unmovedx

    ; Now we calculate move to new square

                    lda fromSquare
                    sta lastSquare
                    lsr
                    lsr
                    lsr
                    sta __fromRow
                    lda toSquare
                    lsr
                    lsr
                    lsr
                    cmp __fromRow
                    beq rowOK
                    bcs .downRow
                    lda fromSquare
                    sbc #7
                    sta fromSquare
                    jmp nowcol
.downRow            lda fromSquare
                    adc #7
                    sta fromSquare
rowOK
nowcol

                    lda fromSquare
                    and #7
                    sta __fromRow
                    lda toSquare
                    and #7
                    cmp __fromRow
                    beq colok
                    bcc .leftCol
                    inc fromSquare
                    jmp colok
.leftCol            dec fromSquare
colok
                    clc
.unmovedx
                    rts




    CHECK_BANK_SIZE "BANK_RECON"

; EOF
