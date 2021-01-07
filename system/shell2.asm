; J/OS Shell2 v1.0
; Second part of the cmnd shell
; File name: shell2.com
;--------------------------------------
; Loaded as application and later
; be replaced by a .com file.
    .org $100
    .code
Prompt:
    ;=== Prompt 1 ===
    sys   #$1A              ; output prompt

    ;=== Input ===
Input:
    move  A, #cmdstr.BUF
    sys   #$17              ; input string (a <- len)
    move  cmdstr.LEN, A          ; command length
    nop
    bze   A, Input
    inc   A                 ; no terminal?
    bze   A, Input

    ;=== check valid cmd ===
    move  A, cmdstr.BUF     ; check valid char
    sub   A, #32
    bpos  A, out_cmd

    ;=== Prompt 2 ===
    move  cmdstr.BUF, #0
    move  A, #cmdstr.BUF
    sys   #$14              ; println command
    jump  Prompt
    
out_cmd:    
    move  A, #cmdstr.BUF
    sys   #$14              ; println command

    ;=== Process command ===
    call  cmdstr.process    ; cmdstr.POS <- @cmnd
                            ; cmdstr.NUM <- num str
    
    ;=== cmd ls ===
cmd_ls:
    move  A, #cmdstr.BUF
    move  B, #CMD_LS
    call  strcmp            ; 0 = match
    bnze  A, cmd_ed

    call  cmdstr.next       ; A <- @param
    bnze  A, +4
    move  A, #PAR_WC        ; use default wc
    move  cmdstr.POS, A

    move  A, cmdstr.POS     ; A <- @wildcard
    sys   #$57              ; list files (->pipe)
    call  less              ; print pipe (<-pipe)
    jump  Prompt

    ;=== cmd ed ===
cmd_ed:
    move  A, #cmdstr.BUF
    move  B, #CMD_ED
    call  strcmp            ; 0 = match
    bnze  A, cmd_cls
    
    call  cmdstr.next       ; A <- @param
    bze   A, serror

    move  A, cmdstr.POS     ; @fname
    move  B, #0             ; RD
    sys   #$50              ; open file (A <- fref)
    move  D, A              ; D = fref
    sys   #$52              ; read file (->pipe)
    move  A, D              ; A = fref
    sys   #$51              ; close file
    
    move  A, cmdstr.POS     ; @fname
    sys   #$16              ; start editor (<-pipe)
    jump  Input

    ;=== cmd cls ===
cmd_cls:
    move  A, #cmdstr.BUF
    move  B, #CMD_CLS
    call  strcmp            ; 0 = match
    bnze  A, cmd_mv
    
    sys   #$10              ; clear screen
    jump  Prompt

    ;=== cmd mv ===
cmd_mv:
    move  A, #cmdstr.BUF
    move  B, #CMD_MV
    call  strcmp            ; 0 = match
    bnze  A, cmd_cp

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #3
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @from
    move  C, cmdstr.POS
    call  cmdstr.next       ; cmdstr.POS <- @to
    move  B, cmdstr.POS
    move  A, C

    sys   #$5A              ; move file
    bze   A, ferror

    move  A, #MOVED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd cp ===
cmd_cp:
    move  A, #cmdstr.BUF
    move  B, #CMD_CP
    call  strcmp            ; 0 = match
    bnze  A, cmd_rm

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #3
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @from
    move  C, cmdstr.POS
    call  cmdstr.next       ; cmdstr.POS <- @to
    move  B, cmdstr.POS
    move  A, C

    sys   #$59              ; copy file
    bze   A, ferror

    move  A, #COPIED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd rm ===
cmd_rm:
    move  A, #cmdstr.BUF
    move  B, #CMD_RM
    call  strcmp            ; 0 = match
    bnze  A, cmd_cd

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #2
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @file
    move  A, cmdstr.POS

    sys   #$58              ; remove file
    bze   A, ferror

    move  A, #REMOVED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd cd ===
cmd_cd:
    move  A, #cmdstr.BUF
    move  B, #CMD_CD
    call  strcmp            ; 0 = match
    bnze  A, load_cmd

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #2
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @file
    move  X, cmdstr.POS
    move  A, [X]            ; A <- drive

    sys   #$5B              ; change dir
    bze   A, ferror

    jump  Prompt

    ;=== check for cmd file ===
load_cmd:
    ; copy cmd to BUFF2
    move  A, #cmdstr.BUF2   ; @dest
    move  B, #cmdstr.BUF    ; @source
    move  C, cmdstr.LEN     ; C = max length
    inc   C                 ; consider '\0'
    call  strcpy
    
    ; add .com extension
    move  A, #cmdstr.BUF2   ; @dest
    move  B, #DCOM          ; @appendix
    move  C, #13            ; max fname length with '\0'
    call  strcat

    ; check if file exists
    move  A, #cmdstr.BUF2
    sys   #$56              ; file size (A <- size)
    bze   A, load_com       ; file does not exist
    
    ; open cmd file
    move  A, #cmdstr.BUF2
    move  B, #114           ; read
    sys   #$50              ; fopen (A <- fref)

    ; read word
    move  B, A
    sys   #$5C              ; read word (A <- word)
    xchg  B, A              ; B = word, A = fref

    ; close file
    sys   #$51  
    
    ; check tag
    skne  A, #cmdstr.COMV1
    jump load_com

    ;=== load .com file ===
    move  A, #cmdstr.BUF2   ; cmd in cmdstr.BUF2
    jump  $4                ; routine resides before $100

    
    ;=== check for .com file ===
load_com:
    move  A, #cmdstr.BUF
    move  B, #DCOM
    call  strrstr           ; check ext
    skeq  A, #1             ; com file?
    jump  load_dh16         ; try .h16

    ;=== load .com file ===
    move  A, #cmdstr.BUF    ; cmd in cmdstr.BUF
    jump  $4                ; routine resides before $100
    
    ;=== check for .h16 file ===
load_dh16:
    move  A, #cmdstr.BUF
    move  B, #DH16
    call  strrstr           ; check ext
    skeq  A, #1             ; h16 file?
    jump  serror

    ;=== load .h16 file ===
    jump  $0C               ; routine resides before $100

    ;=== error ===
serror:
    move  A, #SERROR
    sys   #$14              ; println
    jump  Prompt

ferror:
    move  A, #FERROR
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
CMD_MV:
    "mv\0"
CMD_CP:
    "cp\0"
CMD_RM:
    "rm\0"
CMD_CD:
    "cd\0"
SERROR:
    "Syntax error!\0"
FERROR:
    "File error!\0"
MOVED:
    "File moved\0"
REMOVED:
    "File(s) removed\0"
COPIED:
    "File copied\0"
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
$include "strcpy.asm"
$include "strcat.asm"
$include "less.asm"
