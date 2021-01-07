;===================================
; Function: hatoi(X)
; Convert hex ASCII (zero terminated string) to integer 
; Input: source pointer in X
; Output: value in A
; Destroys: B
;===================================

start:  move    A, #0
loop:   move    B, [X]+
        bze     B, +exit            ; end of string

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
a_to_f: and     B, #$DF             ; use uppercase only
        skgt    B, #$40             ; B > '/'
        jump    +exit               ; EXIT
        sklt    B, #$47             ; B < 'G'
        jump    +exit               ; EXIT
        ; THEN convert value
        sub     B, #$37
        shl     A, #4
        add     A, B
        jump    +loop

exit:   ret
