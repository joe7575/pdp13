; Punch a memory block to tape (Telewriter v1.0)
; Code start address is $100
; Size in words is $200

        .org $F10
        .code

START:  move    X, #$100
        move    B, #$200

LOOP:   out     #0, [X]+    
        dbnz    B, +LOOP
        halt

