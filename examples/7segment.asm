; 7 segment demo v1.0
; PDP13 7-Segment on port #0

    move A, #$80    ; 'value' command
    move B, #00     ; value in B

loop:
    add  B, #01
    and  B, #$0F    ; values from 0 to 15
    out #00, A
    nop
    nop
    jump loop
    
