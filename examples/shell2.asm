; Shell program for the Terminal v1.0 (part1)
; Resides below address $100
BUFF1 = $00C0     ; 64 chars

; Variables ($E8 - $EF)
CMDLEN = $E8
FNAME  = $EA ; @fname

; Used:
; C = num strings
; D = tmp
    .org $100
    .code
Prompt:
    ;=== Prompt 1 ===
    sys   #$1A              ; output prompt

    ;=== Input ===
Input:
    move  A, #BUFF1
    sys   #$17              ; input string (len->A)
    nop
    bze   A, Input
    inc   A                 ; no terminal?
    bze   A, Input
    dec   A
    move  CMDLEN, A         ; command length

    ;=== Prompt 2 ===
    move  A, #BUFF1
    sys   #$14              ; println command

    ;=== Process command ===
    move  A, #BUFF1
    move  B, #32
    call  Strsplit          ; A <- num strings
    move  C, A              ; C <- num strings
    
    ;=== cmd ls ===
cmd_ls:
    move  A, #BUFF1
    move  B, #CMD_LS
    call  Strcmp            ; 0=match
    bnze  A, cmd_ed
    move  A, #BUFF1         ; search param1
    move  B, CMDLEN         ; B <- command length
    call  Nextstr           ; A <- file pattern
    sys   #$57              ; list files (->SM)
    sys   #$18              ; print SM (<-SM)
    jump  Prompt

    ;=== cmd ed ===
cmd_ed:
    move  A, #BUFF1
    move  B, #CMD_ED
    call  Strcmp            ; 0=match
    bnze  A, cmd_cls
    skeq  C, #2
    jump  Error
    move  A, #BUFF1         ; search param1
    move  B, CMDLEN         ; B <- command length
    call  Nextstr           ; A <- file pattern
    move  FNAME, A          
    move  B, #0             ; RD
    sys   #$50              ; open file (A <- fref)
    move  D, A              ; D <- fref
    sys   #$52              ; read file (->SM)
    move  A, D              ; A <- fref
    sys   #$51              ; close file
    move  A, FNAME
    sys   #$16              ; start editor (<-SM)
    jump  Input

    ;=== cmd cls ===
cmd_cls:
    move  A, #BUFF1
    move  B, #CMD_CLS
    call  Strcmp            ; 0=match
    bnze  A, load_com
    sys   #$10              ; clear screen
    jump  Prompt

    ;=== load com ===
load_com:
    move  A, #BUFF1
    sys   #$56              ; file size (A <- size)
    bze   A, Prompt         ; file does not exist
    move  A, #BUFF1
    move  B, #DCOM
    call  Strrstr
    skeq  A, #1             ; com file?
    jump  Prompt  ;dh16

    ;=== load .com file ===
    jump  $4                ; routine resides before $100
    
    ;=== load .h16 file ===
dh16:
    move  A, #BUFF1
    move  B, #DH16
    call  Strrstr
    skeq  A, #1             ; h16 file?
    jump  Error
    move  A, #BUFF1
    sys   #$72              ; load h16 file
    move  SP, #0
    jump  $100              ; start of program on $100

    ;=== error ===
Error:
    move  A, #ERROR
    sys   #$14              ; println
    jump  Prompt

  
    .text
CMD_LS:
    "ls\0"
CMD_ED:
    "ed\0"
CMD_CLS:
    "cls\0"
ERROR:
    "Syntax error!\0"
DCOM:
    ".com\0"
DH16:
    ".h16\0"

$include "strstrip.asm"
$include "strsplit.asm"
$include "strcmp.asm"
$include "nextstr.asm"
$include "strrstr.asm"
