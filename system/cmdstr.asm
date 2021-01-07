;=============================================
; Command string functions and variabels
;=============================================

; Global defines
COMV1  = $2001      ; version tag

; Global command string variables ($B8 - $BF)
LEN  = $00BD      ; command string length
POS  = $00BE      ; command string current pos
NUM  = $00BF      ; num of command strings
BUF  = $00C0      ; command string buffer (64 chars)
BUF2 = $0F00      ; behind shell2

    .code
;===================================
; process
; Prepare command string parameter parsing
;===================================
process:
    ;=== Process command ===
    move  A, #BUF
    move  POS, A            ; init
    call  strlen
    move  LEN, A            ; command length
    
    move  A, #BUF
    move  B, #32
    call  strsplit          ; A = num str
    move  NUM, A
    ret

;===================================
; next
; Set POS no next param
; Result in A: 1=param, 0=no param
;===================================
next:
    ;=== determine next string ===
    push  B
    dec   NUM
    move  A, NUM
    bnze  A, +3
    move  A, #0             ; no param
    pop   B
    ret

    move  A, POS
    move  B, LEN
    call  nextstr           ; A = str pos
    move  POS, A
    move  A, #1             ; param
    pop   B
    ret

$include "strsplit.asm"
$include "nextstr.asm"
$include "strlen.asm"
