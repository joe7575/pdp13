; Read and send chars from/to Telewriter
; Using I/O (TTY) for input
; TTY on I/O port 0

INP_CNTR = #$3E
OUT_CNTR = #$3F
INP_BUFF = #$40     ; 64 chars
OUT_BUFF = #$80     ; 64 chars
TTY_OUT  = #0       ; I/O addr (port-num * 8)
TTY_STS  = #1       ; I/O addr (port-num * 8 + 1)
TTY_INP  = #2       ; I/O addr (port-num * 8 + 2)
LF       = #10      ; line feed

        .code

ECHO:   in      A, TTY_STS
        bze     A, +ECHO            ; rx char num == 0: repeat

        move    X, INP_BUFF         ; use input buffer for the data
input:  in      [X]+, TTY_INP       ; input a char
        dbnz    A, +input
        sub     X, INP_BUFF         ; calc number of chars
        move    A, X

        move    X, INP_BUFF         ; use input buffer again
output: out     TTY_OUT, [X]+       ; output a char
        dbnz    A, +output

        out     TTY_OUT, LF            
        
        jump    +ECHO
