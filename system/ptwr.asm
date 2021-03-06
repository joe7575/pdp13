;===================================
; Tool: ptwr
; Copy .h16/txt file from file system
; to punch tape
;===================================

    .org $100
    .code

    move  A, B          ; com v1 tag $2001

    ; check params
    move  A, cmdstr.NUM ; check num strings
    skeq  A #2
    jump  error

    ; open file
    call  cmdstr.next   ; cmdstr.POS <- @fname
    move  A, cmdstr.POS
    move  B, #114       ; read
    sys   #$50          ; fopen (A <- fref)
    move  B, A          ; B = fref

    ; read file
    sys   #$52          ; read file (>pipe)
    bze   A, error

    ; close file
    move  A, B
    sys   #$51  

    ; write tape
    sys   #$4           ; read tape (<pipe)
    bze   A, error

    ; ready
    move  A, #READY
    sys   #$14          ; println
    jump  exit

    ; error
error:
    move  A, #ERROR
    sys   #$14          ; println
    jump  exit

    ; exit
exit:
    sys   #$71          ; warm start


    .text
READY:
    "file copied\0"
ERROR:
    "Syntax error\0"

$include "cmdstr.asm"

