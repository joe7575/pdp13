; Input string demo v1.0

Start:
    move  A, #TEXT1
    sys   #0        ; output text

    move  A, #$100
    sys   #1        ; read string from telewriter
    bze   A, -5     ; val == 0: branch to move

    move  X, #$100  ; src ptr
    move  Y, #TEXT3 ; dst ptr

    move [Y]+, [X]+ ; copy char
    dbnz A, -3

    move [Y], #0    ; zero terminated string

    move  A, #TEXT2
    sys   #0        ; output text

    jump  Start

    .text
TEXT1:
    "Enter "
    "text\0"
TEXT2:
    "You entered: "
TEXT3:
