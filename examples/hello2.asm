; "Hello world" for the Telewriter v1.0
; Outputs text via 'sys 0' instruction
; Connect Telewriter (TTY) to I/O port 0

; TTY (sys 0) definitions
INP_CNTR = $3E      ; char counter
OUT_CNTR = $3F      ; char counter
INP_BUFF = $40      ; RX buffer (64 chars)
OUT_BUFF = $80      ; TX buffer (64 chars)
TTY_ADDR = #0       ; I/O addr (port-num * 8)

        .code

HELLO2: move    X, #text            ; source address
        move    Y, #OUT_BUFF        ; destination address

loop:   move    [Y]+, [X]
        bnze    [X]+, +loop

        sub     Y, #OUT_BUFF        ; calc string size
        move    OUT_CNTR, Y         ; store string size

        move    A, #1               ; TTY output
        move    B, TTY_ADDR         ; I/O port
        sys     0
        
        halt

        .text
       
text:   "Hello "
        "World 2!\n\0"  ; \n is needed for the Telewriter, \0 as end mark for the loop

