; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

                SEG.U variables
                ORG $80

squareToDraw              ds 1
rnd                             ds 1                ; random
drawDelay                       ds 1
lastSquareX12                   ds 1

drawCount                       ds 1
fromX12                         ds 1
toX12                           ds 1
originX12                       ds 1

cursorX12                       ds 1

mdelay                          ds 1
ccur                            ds 1
savedBank                       ds 1                ; switched-in bank for FIXED returns
aiState                         ds 1                ; state
aiFlashDelay                    ds 1

aiMoveIndex                     ds 1

aiFlashPhase                    ds 1

Evaluation                      ds 2                ; tracks value of the board position

currentPiece                    ds 1
currentSquare                   ds 1
enPassantPawn                   ds 1                ; TODO - this belongs in PLY bank
currentPly                      ds 1

piecelistIndex                  ds 1
sideToMove                      ds 1                ; d7 == side, 0=white, 128 = black
fromPiece                       ds 1
lastPiece                       ds 1
previousPiece                   ds 1

Platform                        ds 1                ; TV system (%0x=NTSC, %10=PAL-50, %11=PAL-60)
