; Color lamp demo v1.0
; PDP13 Color Lamp on port #1

    move A, #$80  ; 'value' command
    move B, #00   ; value in B

loop:
    and  B, #$3F  ; values from 1 to 64
    add  B, #01
    out #01, A
    nop           ; delay
    jump loop
    
