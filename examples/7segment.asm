; 7 segment demo v1.0
; PDP13 7-Segment on port #0

    move A, #$81    ; 7seg command
    move B, #00     ; hex value

loop:
    add  B, #01
    and  B, #$0F    ; values from 0 to 15
    out #0, A
    nop
    nop
    jump loop
    
