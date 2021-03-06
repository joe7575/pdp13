; Input number demo v1.0
; PDP13 Color Lamp on port #1

Start:
    move    A, #TEXT1
    sys     #0

    sys   #2       ; read number from telewriter
    bneg  A, -3    ; val >= $8000: branch to loop

    move  B, A     ; number to B
    move  A, #$80  ; value command to A
    out   #01, A   ; send value to color lamp

    move    A, #TEXT2
    sys     #0

    jump  Start

    .text
TEXT1:
    "Enter "
    "color "
    "(1..64)\0"
TEXT2:
    "Color set\0"
