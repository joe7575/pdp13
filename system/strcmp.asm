;===================================
; strcmp(A, B)
; A = @string 1
; B = @string 2
; A <- 0=equal
;===================================

    .code
start:
    push  X                 ; ptr1
    push  Y                 ; ptr2
    move  X, A
    move  Y, B

loop1:
    bze   [X], endloop1
    skne  [X]+, [Y]+
    jump  loop1

    dec X
    dec Y

endloop1:
    move A, [X]
    sub  A, [Y]

    pop   Y
    pop   X
    ret
