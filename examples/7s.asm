; 7-Segement Demo v1.0
; output the 16 possible values on the 7-segment block on port 1

        .code
        
SEVENSEG:
        move    A, #0           ; start value
loop:   out     #8, A
        inc     A
        and     A, #$0F         ; keep value in range 0..15
        dly                     ; slow down
        dly
        dly
        dly
        dly
        jump    +loop
