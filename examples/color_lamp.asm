; Color lamp demo v1.0
; PDP13 Color Lamp on port #0

    move A, #2      ; color command
    move B, #00     ; color start value

loop:
    and  B, #$3F    ; values from 1 to 64
    add  B, #01
    out #00, A
    nop             ; delay
    jump loop
    
