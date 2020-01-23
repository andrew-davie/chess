; Chess
; Atari 2600 Chess display system
; Copyright (c) 2019-2020 Andrew Davie
; andrew@taswegian.com

                SEG.U variables
                ORG $80
drawPieceNumber                 ds 1        ; partial - square being drawn

rnd                             ds 1        ; random
doubleBufferBase                ds 1        ; switcher for which draw buffer in use points to DRAW one
drawPhase                       ds 1        ; ticks through the board draw process
drawDelay                       ds 1
lastSquare                      ds 1
drawCount                       ds 1
snail                           ds 1
title_colour_table              ds 2
currentPiece                    ds 1
currentSquare                   ds 1
returnBank                      ds 1
enPassantPawn                   ds 1        ; TODO - this belongs in PLY bank

fromSquare                      ds 1
fromPiece                       ds 1
toSquare                        ds 1
toPiece                         ds 1
lastPiece                       ds 1
__fromRow                       ds 1
previousPiece                   ds 1
movePointer                     ds 1

Platform                        ds 1        ; TV system (%0x=NTSC, %10=PAL-50, %11=PAL-60)
BufferedJoystick                ds 1        ; player joystick input
PreviousJoystick                ds 1
;BGColour                        ds 1
colour_table                    ds 2

Board_AddressR                  ds 2
Board_AddressW                  ds 2
ROM_Bank                        ds 1            ; last switched ROM bank (not accessible if RAM subsequently switched)
RAM_Bank                        ds 1


ObjIterator                     ds 1            ; count UP iterator over objects
