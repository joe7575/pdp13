; UDP receive v1.0
; Read string from remote CPU on port #2
; and write to telewriter.
; This demo requires the COMM ROM chip.

start:
    move  B, #2      ; port # in B
    move  A, #$100   ; addr in A
    sys   #$41       ; udp recv (A <- num)
    nop
    bneg  A, exit    ; A < 0: exit
    bze   A, start   ; 0 => no msg received
    
    move  X, #$100   ; src ptr
    move  Y, #TEXT2  ; dst ptr

    move  [Y]+, [X]+ ; copy char
    dbnz  A, -3

    move  [Y], #0    ; end-of-str

    move  A, #TEXT1
    sys   #$0        ; output text

    jump  start

exit:
    halt

    .text
TEXT1:
    "Received: "
TEXT2:    
