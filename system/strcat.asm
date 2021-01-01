;===================================
; Strcat(A, B, C)
; A = @dest string
; B = @source string
; C = max len for dest
; A <- num bytes
; requires: Strlen
;===================================
$include "strlen.asm"

    .code
Strcat:
    push  X
    push  Y
    push  C
    move  Y, B
    dec   C             ; for the trailing zero

    ;=== calc end of dest
    move  X, A
    call  Strlen
    add   X, A
    sub   C, A

    ;=== check length ===
    bpos  C, loop
    move  A, #0
    pop   C
    jump  exit

    ;=== copy char ===
loop:
    move  [X]+, [Y]+
    bze   [Y], endloop
    dbnz  C, loop

endloop:
    move  [X], #0       ; copy trailing zero

    ;=== calc size ===
    move  A, C          
    pop   C
    xchg  A, C
    sub   A, C

    ; === exit ===
exit:
    pop   Y
    pop   X

    ret

