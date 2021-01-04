;=============================================
; Command string functions and variabels
;=============================================

; Global defines
COMV1  = $2001      ; version tag

; Global command string variables ($B8 - $BF)
CSLEN  = $00BD      ; CS length
CSPOS  = $00BE      ; CS current pos
CSNUM  = $00BF      ; num of CSs
CSBUF  = $00C0      ; CS buffer (64 chars)
BUFF2  = $0F00      ; behind shell2

    .code
;===================================
; CSprocess
; Prepare CS parameter parsing
;===================================
CSprocess:
    ;=== Process command ===
    move  A, #CSBUF
    move  CSPOS, A          ; init
    call  Strlen
    move  CSLEN, A          ; command length
    
    move  A, #CSBUF
    move  B, #32
    call  Strsplit          ; A = num str
    move  CSNUM, A
    ret

;===================================
; CSprocess
; Set CSPOS no next param
; Result in A: 1=param, 0=no param
;===================================
CSnext:
    ;=== determine next string ===
    push  B
    dec   CSNUM
    move  A, CSNUM
    bnze  A, +3
    move  A, #0             ; no param
    pop   B
    ret

    move  A, CSPOS
    move  B, CSLEN
    call  Nextstr           ; A = str pos
    move  CSPOS, A
    move  A, #1             ; param
    pop   B
    ret

$include "strsplit.asm"
$include "nextstr.asm"
$include "strlen.asm"
