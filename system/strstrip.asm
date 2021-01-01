;===================================
; Strstrip(A)
; A = @string
; A <- @new string
;===================================
    .code
Strstrip:
    push  X
    move  X, A

    ;=== skip leading blanks ===
loop1:
    skne  [X]+, #32
    jump  loop1
    dec   X
    move  A, X    ; new start of string
    
    ;=== search end of string ===
loop2:    
    skeq  [X]+, #0
    jump  loop2
    dec   X
    dec   X
    
    ;=== split trailing blanks ===
loop3:
    skeq  [X], #32
    jump  exit
    move  [X], #0
    dec   X
    jump  loop3

exit:
    pop   X
    ret
