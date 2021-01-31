; Time of day on four 7-segment blocks
; Connect the 7-segement blocks to port
; #0/#1 for hours and #2/#3 for minutes
; (c) 2021 by Joe

; value out(port, val)
$macro valout 2
    move  A, #$80
    move  B, %2
    out   #%1, A
$endmacro

    .code
    .org $100

    move A, B  ; com tag

start:
    sys  #$90  ; A < minutes
    move D, A  ; store val

    ; hours, 1. digit
    move C, D
    div  C, #600
    valout 0 C

    ; hours, 2. digit
    move C, D
    div  C, #60
    mod  C, #10
    valout 1 C

    ; minutes, 1. digit
    move C, D
    mod  C, #60
    div  C, #10
    valout 2 C

    ; minutes, 2. digit
    move C, D
    mod  C, #10
    valout 3 C

    ; wait one sec
    move A, #10
pause:
    nop
    dbnz A, pause

    jump start

