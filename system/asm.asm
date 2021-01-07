; J/OS Assembler
; Start from console with 'asm name.asm'
;

    .org $100
    .code

    move  A, B      ; com v1 tag $2001

    ; check params
    move  A, cmdstr.NUM     ; check num strings
    skne  A #1
    jump  error
    move  C, A              ; C = num str

    ; fname
fname:
    call  cmdstr.next       ; cmdstr.POS <- @fname
    move  A, cmdstr.POS

    ; options
    move  B, #NO_PARAM
    skeq  C, #3
    jump  main
    
    call  cmdstr.next       ; cmdstr.POS <- @options
    move  B, cmdstr.POS

    ; call asm
main:
    sys   #$200             ; asm (->pipe)
    bze   A, error
    call  less
    jump  exit

    ;=== param error ===
error:
    move  A, #ERROR
    sys   #$14      ; println
    sys   #$71      ; warm start

    ;=== output pipe ===
exit:
    sys   #$71      ; warm start

    .text

NO_PARAM:
    "\0"

ERROR:
    "Param error!\0"

$include "cmdstr.asm"
$include "less.asm"
