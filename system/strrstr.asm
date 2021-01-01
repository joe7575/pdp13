;===================================
; Strrstr(A, B)
; Function returns 1 if string 1 ends with String 2.
; A = @string 1
; B = @string 2
; A <- 1=match
;===================================
    .code
Strrstr:
    push  X
    push  Y
    move  X, A
    move  Y, B

    ;=== search end of string A ===
loop1:
    skeq  [X]+, #0
    jump  loop1
    dec   X
    dec   X

    ;=== search end of string B ===
loop2:
    skeq  [Y]+, #0
    jump  loop2
    dec   Y
    dec   Y

    ;=== compare from right ===
loop3:
    skeq  [X], [Y]
    jump  ret_0
    skne  B, Y
    jump  ret_1
    dec   X
    dec   Y
    jump  loop3

ret_0:
    move  A, #0
    pop   Y
    pop   X
    ret
ret_1:
    move  A, #1
    pop   Y
    pop   X
    ret
