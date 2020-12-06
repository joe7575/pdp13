; Play of colors with the lamp

    move A, #2    ; color command
    move B, #00   ; color value

loop:
    and  B, #$3F
    add  B, #01
    out #00, A
    out #01, A
    out #02, A
    out #03, A
    jump loop
    
