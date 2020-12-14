; Input string demo v1.0

Start:
    move  A, #TEXT1
    sys   #0        ; output text

    move  A, #$100
    sys   #1        ; read string from telewriter
    bneg  A, -5     ; val >= $8000: branch to move

    move  X, #$100  ; src ptr
    move  Y, #TEXT3 ; dst ptr

    move [Y]+, [X]+ ; copy char
    dbnz A, -3

    move [Y], #0    ; zero terminated string

    move  A, #6     ; delay
    nop
    dbnz  A, -3

    move  A, #TEXT2
    sys   #0        ; output text

    move A, #6
    nop
    dbnz A, -3

    jump  Start

    .text
TEXT1:
    "Enter "
    "text\0"
TEXT2:
    "You entered: "
TEXT3:
