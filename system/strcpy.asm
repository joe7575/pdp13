;===================================
; strcpy(A, B, C)
; A = @dest address
; B = @source string
; C = max len for dest incl. \0
; A <- num chars
;===================================
    .code
start:
    push  X
    push  Y
    push  C
    move  X, A
    move  Y, B
    dec   C             ; for the trailing zero

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
    pop   Y
    pop   X

    ret

