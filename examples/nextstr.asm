;===================================
; Nextstr(A)
; Search the first char of the next string behing string @A
; A = @string
; B = max len
; Used: X
; Result: A <- @next string
;===================================
    .code

Nextstr:
    move X, A
    add  X, B
    move [X], #0            ; end of search
    move X, A
    
    ;=== skip chars ===
loop1:    
    bnze [X]+, loop1
    
    ;=== skip zeros ===
loop2:
    bze  [X]+, loop2
    dec  X
    move A, X

    ret
