; UDP receive v1.0
; Read string from remote CPU on port #2
; and write to telewriter.
; This demo requires the COMM ROM chip.

start:
    move  B, #2     ; port # in B
    move  A, #$100  ; addr in A
    sys   #41       ; udp recv
    dec   A
    bnze  A, start  ; 0 => msg received

    move  A, #$100
    sys   #0        ; output string to telewriter
    jump  start
    
