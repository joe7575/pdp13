;===================================
; Tool: ptrd
; Copy .h16/txt file from punch tape
; to file system
;===================================

    .org $100
    .code

    move  A, B          ; com v1 tag $2001

    ; check params
    move  A, cmdstr.NUM ; check num strings
    skeq  A #2
    jump  error

    ; read tape
    sys   #$3           ; read tape to pipe
    bze   A, error

    ; open file
    call  cmdstr.next   ; cmdstr.POS <- @fname
    move  A, cmdstr.POS
    move  B, #119       ; write
    sys   #$50          ; fopen (A <- fref)
    move  B, A          ; B = fref

    ; store file
    sys   #$54          ; write file (<pipe)
    bze   A, error

    ; close file
    move  A, B
    sys   #$51  

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

