
    IF !TEST_POSITION

    .byte WHITE|Q, 25
    .byte WHITE|B, 24
    .byte WHITE|B, 27
    .byte WHITE|R, 22
    .byte WHITE|R, 29
    .byte WHITE|N, 23
    .byte WHITE|N, 28

    .byte WHITE|WP, 35
    .byte WHITE|WP, 36
    .byte WHITE|WP, 34
    .byte WHITE|WP, 37
    .byte WHITE|WP, 33
    .byte WHITE|WP, 38
    .byte WHITE|WP, 32
    .byte WHITE|WP, 39

    .byte WHITE|K, 26

    .byte BLACK|Q, 95
    .byte BLACK|B, 94
    .byte BLACK|B, 97
    .byte BLACK|R, 92
    .byte BLACK|R, 99
    .byte BLACK|N, 93
    .byte BLACK|N, 98

    .byte BLACK|BP, 85
    .byte BLACK|BP, 86
    .byte BLACK|BP, 84
    .byte BLACK|BP, 87
    .byte BLACK|BP, 83
    .byte BLACK|BP, 88
    .byte BLACK|BP, 82
    .byte BLACK|BP, 89

    .byte BLACK|K, 96

    .byte 0 ;end

    ELSE ; test position...


    IF 0

        .byte WHITE|K, 28
        .byte WHITE|WP, 37
        .byte WHITE|WP, 38
        .byte WHITE|WP, 53
        .byte WHITE|WP, 49
        .byte WHITE|WP, 32
        .byte WHITE|R, 27
        .byte WHITE|B, 46
        .byte WHITE|R, 54

        .byte BLACK|BP, 56
        .byte BLACK|BP, 87
        .byte BLACK|BP, 88
        .byte BLACK|BP, 89
        .byte BLACK|BP, 84
        .byte BLACK|B, 66
        .byte BLACK|R, 69
        .byte BLACK|K, 98

        .byte BLACK|R, 92



    ENDIF


    IF 1
    ; En passant test

        .byte BLACK|BP, 88
        .byte BLACK|BP, 86

        .byte WHITE|WP, 67
        .byte WHITE|K, 52


    ENDIF




    IF 0


    ;.byte BLACK|R, 97
    .byte BLACK|K, 98
    .byte BLACK|BP, 87
    .byte BLACK|BP, 88
    .byte BLACK|BP, 89
;    .byte BLACK|B, 76


    .byte WHITE|R,28
    .byte WHITE|Q,58
 ;   .byte WHITE|N,65
    ENDIF

    IF 0
        ;.byte WHITE|WP, 56


    .byte BLACK|K, 98


    .byte WHITE|R,29
    .byte WHITE|Q,49
    .byte WHITE|N,65
    ENDIF 
    .byte 0 ;end

    ENDIF


