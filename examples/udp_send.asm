; UDP send v1.0
; Read string from telewriter and send
; to remote CPU on port #2.
; This demo requires the COMM ROM chip.

start:
    move  A, #TEXT
    sys   #0        ; output text

loop:
    move  A, #$100
    sys   #1        ; read string from telewriter
    bneg  A, loop  ; val >= $8000: -> loop

    move  B, #2     ; port # in B
    move  A, #$100  ; addr in A
    sys   #$40      ; udp send
    jump  start

   .text
TEXT:
    "Enter "
    "text\0"
