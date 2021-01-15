; h16com v1.0
; .h16 to .com conversion tool
; File name: h16com.h16
;--------------------------------------
; Convert a .h16 file to .com format
; fname without ext (.h16/.com) on $C0
; syntax; h16com <fname> (w/o ext)

FSIZE = $FE7E   ; file size
EOSTR = $FE7F   ; @end-of-string

    .code
    ;### entry ===
    .org $0100
    jump main
    
    ;### main ===
    .org $FE80
main:
    move  A, #HELLO
    sys   #$14              ; println
    
    ;=== determine param fname ===
    move  A, cmdstr.NUM     ; check num strings
    dec   A 
    bze   A, error1         ; no param: error
    call  cmdstr.next       ; cmdstr.POS <- @fname

    ;=== determine string len ===
    move  A, cmdstr.POS
    call  strlen            ; A <- size
    add   A, cmdstr.POS     ; C <- @end-of-str
    move  EOSTR, A

    ;=== add .h16 ext ===
    move  A, cmdstr.POS
    move  B, #DH16
    move  C, #64
    call  strcat

    ;=== determine file size
    move  A, cmdstr.POS
    sys   #$77              ; A <- fsize
    bze   A, error2
    move  FSIZE, A 
    
    ;=== load .h16 file ===
    move  A, cmdstr.POS     ; A = @fname
    sys   #$75              ; load .h16 file
   
    ;=== add .com ext ===
    move  X, EOSTR
    move  [X], #0           ; cut ext
    move  A, cmdstr.POS
    move  B, #DCOM
    move  C, #64
    call  strcat            ; add .com

    ;=== store .com ===
    move  A, cmdstr.POS
    move  B, FSIZE
    sys   #$7A

    ;=== ready ===
    move  A, #READY
    sys   #$14              ; println

    ;=== exit ===
exit:
    sys  #$71               ; warm start

    ;=== error1 ===
error1:
    move  A, #ERROR1
    sys   #$14              ; println
    jump  exit

    ;=== error2 ===
error2:
    move  A, #ERROR2
    sys   #$14              ; println
    jump  exit

    .text
HELLO:
    "com-to-h16 converter v1.0\0"
ERROR1:
    "Param error!\0"
ERROR2:
    "File error!\0"
READY:
    "File converted.\0"
DCOM:
    ".com\0"
DH16:
    ".h16\0"

$include "cmdstr.asm"
$include "strcat.asm"
$include "strlen.asm"


