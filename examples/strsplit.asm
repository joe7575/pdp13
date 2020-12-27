;===================================
; Strsplit(A)
; A = @string
; B = separator
; A <- num strings
;===================================
    .code
Strsplit:
    push  X                 ; ptr
    move  X, A
    move  A, #1             ; cnt
    
loop1:
    call  find_blank
    bze   [X], endloop1
    move  [X]+, #0
    inc   A
    jump  loop1
    
endloop1:
    pop   X
    ret


find_blank:
    skne  B, [X]
    jump  endloop2
    bnze  [X]+, find_blank
    dec   X
    
endloop2:
    ret
