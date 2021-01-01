; J/OS Shell2 v1.0
; Copy file to Tape Drive and convert
; to .com file via 'h16com.h16'
; File name: shell2.com
;--------------------------------------
; Resides above address $100

    .org $100
    .code
Prompt:
    ;=== Prompt 1 ===
    sys   #$1A              ; output prompt

    ;=== Input ===
Input:
    move  A, #CSBUF
    sys   #$17              ; input string (len->A)
    move  CSLEN, A          ; command length
    nop
    bze   A, Input
    inc   A                 ; no terminal?
    bze   A, Input

    ;=== Prompt 2 ===
    move  A, #CSBUF
    sys   #$14              ; println command

    ;=== Process command ===
    call  CSprocess
    
    ;=== cmd ls ===
cmd_ls:
    move  A, #CSBUF
    move  B, #CMD_LS
    call  Strcmp            ; 0=match
    bnze  A, cmd_ed

    call  CSnext            ; A <- 1=param
    bnze  A, +4
    move  A, #PAR_WC        ; use default wc
    move  CSPOS, A

    move  A, CSPOS          ; a <- @wildcard
    sys   #$57              ; list files (->SM)
    sys   #$18              ; print SM (<-SM)
    jump  Prompt

    ;=== cmd ed ===
cmd_ed:
    move  A, #CSBUF
    move  B, #CMD_ED
    call  Strcmp            ; 0=match
    bnze  A, cmd_cls
    
    call  CSnext            ; A <- 1=param
    bze   A, Error

    move  A, CSPOS          ; @fname
    move  B, #0             ; RD
    sys   #$50              ; open file (A <- fref)
    move  D, A              ; D <- fref
    sys   #$52              ; read file (->SM)
    move  A, D              ; A <- fref
    sys   #$51              ; close file
    
    move  A, CSPOS          ; @fname
    sys   #$16              ; start editor (<-SM)
    jump  Input

    ;=== cmd cls ===
cmd_cls:
    move  A, #CSBUF
    move  B, #CMD_CLS
    call  Strcmp            ; 0=match
    bnze  A, load_com
    
    sys   #$10              ; clear screen
    jump  Prompt

    ;=== check for .com com ===
load_com:
    move  A, #CSBUF
    sys   #$56              ; file size (A <- size)
    bze   A, Prompt         ; file does not exist
    
    move  A, #CSBUF
    move  B, #DCOM
    call  Strrstr           ; check ext
    skeq  A, #1             ; com file?
    jump  dh16              ; try .h16

    ;=== load .com file ===
    jump  $4                ; routine resides before $100
    
    ;=== check for .h16 file ===
dh16:
    move  A, #CSBUF
    sys   #$56              ; file size (A <- size)
    bze   A, Prompt         ; file does not exist
    
    move  A, #CSBUF
    move  B, #DH16
    call  Strrstr           ; check ext
    skeq  A, #1             ; h16 file?
    jump  Error

    ;=== load .h16 file ===
    jump  $0C               ; routine resides before $100

    ;=== error ===
Error:
    move  A, #ERROR
    sys   #$14              ; println
    jump  Prompt

  
    .text
CMD_LS:
    "ls\0"
PAR_WC:
    "*\0"
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

$include "cmdstr.asm"
$include "strstrip.asm"
$include "strsplit.asm"
$include "strcmp.asm"
$include "nextstr.asm"
$include "strrstr.asm"
