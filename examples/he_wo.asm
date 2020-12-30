; Hello world for the Terminal in COM format

    .org $100
    .code
    move    A, #TEXT
    sys     #$14        ; println
    sys     #$71        ; warm start

    .text
TEXT:
    "Hello "
    "World\0"
