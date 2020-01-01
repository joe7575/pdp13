; Boot Loader v1.0
;
; Deposite the code at the end of your RAM (e.g. $0F00)
; 1) Connect Telewriter (TTY) to I/O port 0
; 2) Deposit and start boot loader via "l F00", "[start]"
; 3) Start Telewriter Tape Reader
; 4) Stop boot loader
; 5) Start loaded program via "l 100". "[start]"

TTY_STS  = #1       ; I/O addr (port-num * 8 + 1)
TTY_INP  = #2       ; I/O addr (port-num * 8 + 2)

        .org $F00
        .code

START:  move    X, #$1000       ; code start address

loop:   in      A, TTY_STS      ; read status from input #0
        bze     A, +loop        ; No data => try again
        in      A, TTY_INP      ; read data from input #1
        move    [X]+, A         ; move data to memory via X
        jump    +loop           ; repeat
        
