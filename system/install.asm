; J/OS Installation Tape v1.0

; Write tape to RAM and start program at address 0
;--------------------------------------

; %1 = terminal message (TEXT)
; %2 = error num (1)
$macro read_tape 2
    move  A, #%1
    sys   #$14              ; println
    call  input

    move  A, #$500          ; any address
    sys   #5                ; read tape name (A <- 1)
    move  B, #%2            ; error number
    bze   A, error

    move  A, #COPY
    sys   #$14              ; println
    
    move  B, #15
    call  sleep
$endmacro


start:
    sys   #$10              ; clear screen
    move  A, #HELLO
    sys   #$14              ; println
    move  A, #NEWLINE
    sys   #$14              ; println

    read_tape TAPE1 1

    read_tape TAPE2 2

    read_tape TAPE3 3

    move  A, #READY
    sys   #$14              ; println

    halt

;===================================
; Function: input
; Wait on input from terminal
;===================================
input:
    move  A, #$500
    sys   #$17      ; terminal input (A<-size)
    nop
    bze   A, input
    ret

;===================================
; Function: sleep
; sleep for the given amount of 600ms ticks
; and simulate tape reading
; Param B: ticks
;===================================
sleep:
    sys   #$6
    nop
    nop
    nop
    nop
    dbnz  B, sleep
    ret

;===================================
; Function: error
; Output error and halt.
; Param B: error number
;===================================
error:
    move  A, #ERROR
    sys   #$13              ; print
    move  A, B
    move  B, #10
    sys   #$12              ; print num
    move  A, #NEWLINE
    sys   #$14              ; println

    halt


    .text
HELLO:
    "J/OS Install v0.1\0"
NEWLINE:
    "\0"

TAPE1:
    "Insert System Tape 1 and press enter\0"
TAPE2:   
    "Insert System Tape 2 and press enter\0"
TAPE3:   
    "Insert System Tape 3 and press enter\0"
COPY:
    "copy files...\0"

READY:
    "Ready. Boot your OS.\0"
    
ERROR:
    "Tape error \0"
    
$include "cmdstr.asm"
$include "strcpy.asm"
$include "strcat.asm"
