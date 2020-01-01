; Hello world for the Telewriter v1.0
; Using sys 0 (TTY) for output
; TTY on I/O port 0


INP_CNTR = $3E
OUT_CNTR = $3F
INP_BUFF = $40      ; 64 chars
OUT_BUFF = $80      ; 64 chars
TTY_ADDR = #0       ; I/O addr (port-num * 8)

LF    = #10
BLANK = #32

        .code

HELLO3: move    X, #OUT_BUFF        ; output buffer as dest addr
        move    OUT_CNTR, #0        ; clear output counter

        move    A, #$DEAD            ; test value
        call    +ITOA
        move    [X]+, BLANK

        move    A, #$DEAD           ; test value
        call    +ITOHA
        move    [X]+, BLANK

        move    A, #$BEEF           ; test value
        call    +ITOA
        move    [X]+, BLANK

        move    A, #$BEEF           ; test value
        call    +ITOHA
        move    [X]+, BLANK

        move    [X]+, LF
        sub     X, #OUT_BUFF        ; calc string size
        move    OUT_CNTR, X         ; store string size
        dly

        move    A, #1               ; TTY output
        move    B, TTY_ADDR         ; I/O port
        sys     0
        
        halt

