; Play of colors with the lamp

    move A, #3    ; 7seg command
    move B, #00   ; hex value

loop:
    add  B, #01
    and  B, #$0F
    out #04, A
    nop
    nop
    nop
    nop
    jump loop
    
