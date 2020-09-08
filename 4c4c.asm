
    .processor 6502
    ORG $1000


N SET 0
    REPEAT 256
    .byte N
N SET N + 1
    REPEND


    lda #'A
    
