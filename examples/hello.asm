; "Hello world" for the Telewriter v1.0
; Outputs text via 'out' instructions
; Connect Telewriter (TTY) to I/O port 0

        .code

HELLO1: move    X, #text            ; source address

loop:   out     #0, [X]             ; output a char
        bnze    [X]+, +loop         ; repeat until zero
        halt

        .text
       
text:   "Hello "
        "world\n\0"      ; \n is needed for the Telewriter, \0 as end mark for the loop


