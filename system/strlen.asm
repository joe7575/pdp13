;===================================
; Strlen(A)
; A = @string
; A <- num chars w/o '\0'
;===================================
    .code
Strlen:
    push  X
    move  X, A
    move  A, #0
    
loop:
    bze   [X]+, endloop
    inc   A
    jump  loop
    
endloop:
    pop   X

    ret

