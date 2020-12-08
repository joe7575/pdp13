; Hello world for the Telewriter v1.0

        .code
START:  move    A, #TEXT
        sys     #0
        halt

        .org $100
        .text
TEXT:   "Hello "
        "World\0"
