;===================================
; Function: itoha(X)
; Convert unsigned integer in A to hex ASCII
; Input: value in A, dest pointer in X
; Output: new dest pointer (end of string)
; Destroys: A, B, C
;===================================

start:  push    #0          ; stack base marker and sting end
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

        move    A, #0
copy:   pop     B
        move    [X]+, B
        inc     A
        bnze    B, +copy
        dec     X
        ret
