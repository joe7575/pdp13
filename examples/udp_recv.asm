; UDP receive v1.0
; Read string from remote CPU on port #1 and write to telewriter

start:
    move  B, #1     ; port # in B
    move  A, #$100  ; addr in A
    sys   #17       ; udp recv
    bze   A, start  ; 1 => msg received

    move  A, #$100
    sys   #0        ; output string to telewriter
    jump  start
    
