; J/OS format disk (delete all files)
; Start from console with 'format.h16'
; 

    .org $100
    .code
    
    move  A, B      ; com v1 tag $2001

    call  cmdstr.next       ; cmdstr.POS <- @param
    move  X, cmdstr.POS
    move  A, [X]
    sys   #$64      ; format disk

    move  A, #TEST
    sys   #$14      ; println

exit:
    sys   #$71      ; warm start

    .text
TEST: "Disk has been formatted.\0"

$include "cmdstr.asm"
