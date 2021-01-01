;=============================================
; Command string functions and variabels
;=============================================

; Global command string variables ($B8 - $BF)
CSLEN  = $00BD      ; CS length
CSPOS  = $00BE      ; CS current pos
CSNUM  = $00BF      ; num of CSs
CSBUF  = $00C0      ; CS buffer (64 chars)

    .code
;===================================
; CSprocess
; Prepare CS parameter parsing
;===================================
CSprocess:
    ;=== Process command ===
    move  A, #CSBUF
    move  CSPOS, A          ; init 
    move  B, #32
    call  Strsplit          ; A = num str
    move  CSNUM, A

;===================================
; CSprocess
; Set CSPOS no next param
; Result in A: 1=param, 0=no param
;===================================
CSnext:
    ;=== determine next string ===
    dec   CSNUM
    move  A, CSNUM
    bnze  A, +2
    move  A, #0             ; no param
    ret
    move  A, CSPOS
    call  Nextstr           ; A = str pos
    move  CSPOS, A
    move  A, #1             ; param
    ret

$include "strsplit.asm"
$include "nextstr.asm"
