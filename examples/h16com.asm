;===================================
; h16com as H16 tool
; Convert a .h16 file to .com format
; fname without ext (.h16/.com) on $C0
; syntax; h16com <fname> (w/o ext)
;===================================
buff1 = $c0
buff2 = $FFE0

    .code
    ;### entry ===
    .org $0100
    jump main
    
    ;### main ===
    .org $FF00
main:
    ;=== search param fname ===
    move  A, #buff1
    call  Strlen
    
    ;=== determine string len ===
    move  A, #buff1
    call  Strlen
    move  C, #buff1
    add   C, A          ; C <- end-of-str

    ;=== add .h16 ===
    move  A, #buff1
    move  B, #DH16
    call  Strcat

    ;=== load h16 file ===
    move  A, #buff1
    sys   #$72
    bze   A, error

    ;=== determine addr min/max ===
    move  A, #buff3
    sys   #$76
    bze   A, error
    
    ;=== add .com ===
    move  X, C
    move  [X], #0
    move  A, #buff1
    move  B, #DH16
    call  Strcat

    ;=== store as com ===
    move  A, #buff3
    move  B, #buff4
    sys   #$77
    bze   A, error
    jump  ready

    ;=== error ===
error:
    move  A, #ERROR
    sys   #$14              ; println
    jump  exit

    ;=== ready ===
ready:
    move  A, #READY
    sys   #$14              ; println
    jump  exit

    ;=== exit ===
exit:
    sys  #$71               ; warm start

    .text
ERROR:
    "File error!\0"
READY:
    "File converted.\0"
DCOM:
    ".com\0"
DH16:
    ".h16\0"

$include "nextstr.asm"
$include "strcat.asm"
$include "strlen.asm"


