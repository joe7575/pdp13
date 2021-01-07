;===================================
; Function: less
; Output screen piece by piece
; from pipe to terminal
; Uses: A
;===================================

    .code
start:
    ; check pipe size
    sys   #$82      ; A <- pipe size
    bze   A, exit

loop:
    ; output pipe
    move  A #15     ; num lines
    sys   #$18      ; print pipe

    ; check pipe size
    sys   #$82      ; A <- pipe size
    bze   A, exit

    ; output text
    move  A, #TEXT
    sys   #$14      ; println

    ; input from terminal
input:
    move  A, #cmdstr.BUF
    sys   #$17      ; terminal input (A<-size)
    nop
    bze   A, input

    ; check for enter
    move  A, cmdstr.BUF
    skeq  A, #26
    jump  exit

    ; next loop
    jump  loop

    ; === exit ===
exit:
    sys   #$83      ; A <- flush pipe
    ret

    .text
TEXT: "press enter...\0"

$include "cmdstr.asm"

