;===================================
; Function: cpyfiles
; Copy file by file according to the
; source file list getting from the pipe
; A = @dest path
; Res A: 1 = num, 0 = error
;===================================

    .code
start:
    ; move dest path to BUF2
    move  B, A          ; B <- @src path
    move  A, #cmdstr.BUF2 ; A <- @dst path
    move  C, #15
    call strcpy
    
    ; check pipe size
    sys   #$82          ; A <- pipe size
    bze   A, exit
    move  C, A          ; C <- pipe size
    
    move  B, #cmdstr.BUF2 ; B <- @dst path
loop:
    ; get next src file from pipe
    move  A, #cmdstr.BUF
    sys   #$81          ; pop pipe

    ; copy file
    move  A, #cmdstr.BUF
    sys   #$59          ; copy file
    bze   A, exit

    ; check pipe size
    sys   #$82          ; A <- pipe size
    bze   A, ok
    jump  loop
    
ok:
    move  A, C          ; A <- num files

    ; === exit ===
exit:
    ret

$include "cmdstr.asm"
$include "strcpy.asm"

