; Hello world for the Telewriter v1.0

    move    A, #TEXT
    sys     #0
    halt

    .text
TEXT:
    "Hello "
    "World\0"
