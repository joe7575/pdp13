;===================================
; strsplit(A)
; A = @string
; B = separator
; A <- num strings
;===================================
; "Hello" => 1
; "Hello   world" => 2
; " Hel lo world " => 3

    .code
start:
    push  X                 ; ptr
    move  X, A
    move  A, #0             ; cnt

    ;=== loop over all strings ===
loop1:
    call  del_blanks
    bze   [X], exit
    inc   A
    call find_blank
    bze   [X], exit
    jump  loop1
    
exit:
    pop   X
    ret

    ;=== find next blank ===
find_blank:
    bze   [X], return
    skne  B, [X]
    jump  return
    inc   X
    jump  find_blank

    ;=== set blanks to zero ===
del_blanks:
    bze   [X], return
    skeq  B, [X]
    jump  return
    move  [X]+, #0
    jump  del_blanks

return:
    ret
