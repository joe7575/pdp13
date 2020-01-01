; Multi demo with jump table for all demos
;
; Stack Pointer on $1000

        .code
        .org $1000
        
        move    SP, #$1000          ; init stack
        jump    +main

        .org $1010
        
main:   jump SEVENSEG ; $1010 7-segement demo on port 1
        jump HELLO1   ; $1012: Hello word on TTY on port 0
        jump HELLO2   ; $1014: Hello word2 via SYS 0 on port 0
        jump HELLO3   ; $1016: number output via SYS 0 on port 0
        jump LAMP     ; $1018: read inport on port 2 and output on 3
        jump ECHO     ; $101A: input/output chars from/to TTY

$include "itoa.asm"
$include "7s.asm"
$include "hello.asm"
$include "hello2.asm"
$include "hello3.asm"
$include "lamp.asm"
$include "tty.asm"
