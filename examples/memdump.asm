; Read address from Telewriter and send memory dump (8 words)
; Using sys 0 (TTY) for input/output
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

DUMP:   sys     0
        bze     A, +DUMP            ; rx char num == 0: repeat

        ; terminate the string with zero
        sklt    A, #64              ; buffer not full
        move    A, #63              ; set X to last char
        add     A, INP_BUFF
        move    X, A
        move    [X], #0             ; end of string
        move    X, INP_BUFF         ; start of string
        call    +HATOI              ; convert input to number, returned in A

        move    OUT_CNTR, #0        ; clear output buffer
        move    X, INP_BUFF         ; use input buffer for the data
input:  in      [X]+, TTY_INP       ; input a char
        dbnz    A, +input
        sub     X, INP_BUFF         ; calc number of chars
        move    A, X

        move    X, INP_BUFF         ; use input buffer again
output: out     TTY_OUT, [X]+       ; output a char
        dbnz    A, +output

        out     TTY_OUT, LF            
        
        jump    +DUMP


        ;#######################################################
        ; Function: HATOI
        ; Convert hex ASCII (zero terminated string) to integer 
        ; Input: source pointer in X
        ; Output: value in A
        ; Destroys: B
HATOI:  move    A, #0
loop:   move    B, [X]+
        bze     B, +exit            ; end of string
        and     B, #$BF             ; use uppercase

        ; IF B > '/' and B < ':' THEN
        skgt    B, #$2F             ; B > '/'
        jump    +exit               ; EXIT
        sklt    B, #$3A             ; B < ':'
        jump    +a_to_f             ; ELSE
        ; THEN convert value
        sub     B, #$30
        shl     A, #4
        add     A, B
        jump    +loop               ; next char

        ; IF B > '@' and B < 'G' THEN
a_to_f: skgt    B, #$40             ; B > '/'
        jump    +exit               ; EXIT
        skgt    B, #$3A             ; B < 'G'
        jump    +a_to_f             ; EXIT
        ; THEN convert value
        sub     B, #$37
        shl     A, #4
        add     A, B
        jump    +loop

exit:   ret
