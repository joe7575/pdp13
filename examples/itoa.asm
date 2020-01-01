; integer-to-ascii & integer-to-hex ascii conversion routines
; v1.0

        ;#######################################################
        ; Function: ITOA
        ; Convert integer in A to ASCII
        ; Input: value in A, dest pointer in X
        ; Output: new dest pointer (end of string)
        ; Destroys: A, B, C
ITOA:   push    #0          ; stack base marker
loop:   move    B, A
        div     B, #10      ; rest in B
        move    C, A
        mod     C, #10      ; digit in C
        add     C, #48
        push    C           ; store on stack
        move    A, B
        bnze    A, +loop    ; next digit
        
copy:   pop     A
        move    [X]+, A
        bnze    A, +copy
        dec     X
        ret

        ;#######################################################
        ; Function: ITOHA
        ; Convert integer in A to hex ASCII
        ; Input: value in A, dest pointer in X
        ; Output: new dest pointer (end of string)
        ; Destroys: A, B, C
ITOHA:  push    #0          ; stack base marker
        move    C, #4       ; num digits
loop:   move    B, A
        div     B, #$10     ; rest in B
        mod     A, #$10     ; digit in C
        sklt    A, #10      ; C < 10 => jmp +2
        add     A, #7       ; A-F offset
        add     A, #48      ; 0-9 offset
        push    A           ; store on stack
        move    A, B
        dbnz    C, +loop    ; next digit

copy:   pop     A
        move    [X]+, A
        bnze    A, +copy
        dec     X
        ret
