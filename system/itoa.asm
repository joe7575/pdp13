        ;#######################################################
        ; Function: ITOA
        ; Convert unsigned integer in A to ASCII
        ; Input: value in A, dest pointer in X
        ; Output: new dest pointer (end of string)
        ; Destroys: A, B, C
ITOA:   push    #0          ; stack base marker and sting end
loop:   move    B, A
        div     B, #10      ; rest in B
        move    C, A
        mod     C, #10      ; digit in C
        add     C, #48
        push    C           ; store on stack
        move    A, B
        bnze    A, +loop    ; next digit
        
        move    A, #0
copy:   pop     B
        move    [X]+, B
        inc     A
        bnze    B, +copy
        dec     X
        ret
