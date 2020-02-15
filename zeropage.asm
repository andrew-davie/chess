; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

                SEG.U variables
                ORG $80
drawPieceNumber                 ds 1        ; partial - square being drawn

rnd                             ds 1        ; random
drawPhase                       ds 1        ; ticks through the board draw process
drawDelay                       ds 1
lastSquare                      ds 1
drawCount                       ds 1
fromX12                         ds 1
toX12                           ds 1
highlight_row                   ds 2
highlight_col                   ds 2
mdelay                          ds 1
ccur                            ds 1
savedBank                       ds 1        ; switched-in bank for FIXED returns
aiPhase                         ds 1        ; human/computer state machine
aiFlashDelay                    ds 1
aiFromSquare                    ds 1
aiToSquare                      ds 1
aiFromSquareX12                 ds 1
aiToSquareX12                   ds 1
aiMoveIndex                     ds 1

aiFlashPhase                    ds 1

currentPiece                    ds 1
currentSquare                   ds 1
returnBank                      ds 1
enPassantPawn                   ds 1        ; TODO - this belongs in PLY bank
followPiece                     ds 1
currentPly                      ds 1
piecelistIndex                  ds 1
sideToMove                      ds 1        ; d7 == side, 0=white, 128 = black
fromSquare                      ds 1
fromPiece                       ds 1
toSquare                        ds 1
toPiece                         ds 1
lastPiece                       ds 1
previousPiece                   ds 1

Platform                        ds 1        ; TV system (%0x=NTSC, %10=PAL-50, %11=PAL-60)
;BufferedJoystick                ds 1        ; player joystick input
;PreviousJoystick                ds 1
;BGColour                        ds 1
aiPiece                         ds 1
