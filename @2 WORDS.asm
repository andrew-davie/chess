
    SLOT 2
    ROMBANK WORDS


;---------------------------------------------------------------------------------------------------

; 'shape' indexes into tables



    MAC BMLO
        .byte <{1}
    ENDM

    MAC BMHI
        .byte >{1}
    ENDM


    MAC SHAPEVEC
        {1} Shape1
        {1} Shape2
    ENDM


    DEF BitmapShapeLO
        SHAPEVEC BMLO

    DEF BitmapShapeHI
        SHAPEVEC BMHI




Shape1
    ; 8 bytes --> mask ptr (-1 = none)
    ; 8 bytes --> shape ptr (-1 = none)

    .byte -1,-1,-1,-1,-1,-1,-1,-1               ; mask (i.e., none)
    .byte 0,-1,-1,-1,-1,-1,-1,-1                ; shape 

Shape2
    .byte 0,1,-1,-1,-1,-1,-1,-1                 ; mask
    .byte 1,2,-1,-1,-1,-1,-1,-1                 ; shape


MaskVector
    .word Mask1
    .word Mask2
    ; ...

Mask1
Mask2
    ds ROW_BITMAP_SIZE, 0    

ShapeVector
    .word Shape0Row0
    .word Shape1Row0
    .word Shape1Row1
    ;....

Shape0Row0
    ds ROW_BITMAP_SIZE, 255

Shape1Row0
    ds ROW_BITMAP_SIZE, 255

Shape1Row1
    ds ROW_BITMAP_SIZE, 255

;this gives 256 total, about 32 shapes max


;---------------------------------------------------------------------------------------------------

    END_BANK

;---------------------------------------------------------------------------------------------------
; EOF
