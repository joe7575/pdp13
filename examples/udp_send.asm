; UDP send v1.0
; Read string from telewriter and send to remote CPU on port #2

start:
    move  A, #$100
    sys   #1        ; read string from telewriter
    bneg  A, start  ; val >= $8000: branch to move

    move  B, #2     ; port # in B
    move  A, #$100  ; addr in A
    sys   #40       ; udp send
    jump  start
