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
    move  A, #CSBUF
    sys   #$17              ; input string (a <- len)
    move  CSLEN, A          ; command length
    nop
    bze   A, Input
    inc   A                 ; no terminal?
    bze   A, Input

    ;=== check valid cmd ===
    move  A, CSBUF         ; check valid char
    sub   A, #32
    bpos  A, out_cmd

    ;=== Prompt 2 ===
    move  CSBUF, #0
    move  A, #CSBUF
    sys   #$14              ; println command
    jump  Prompt
    
out_cmd:    
    move  A, #CSBUF
    sys   #$14              ; println command

    ;=== Process command ===
    call  CSprocess         ; CSPOS <- @cmnd
                            ; CSNUM <- num str
    
    ;=== cmd ls ===
cmd_ls:
    move  A, #CSBUF
    move  B, #CMD_LS
    call  Strcmp            ; 0 = match
    bnze  A, cmd_ed

    call  CSnext            ; A <- @param
    bnze  A, +4
    move  A, #PAR_WC        ; use default wc
    move  CSPOS, A

    move  A, CSPOS          ; A <- @wildcard
    sys   #$57              ; list files (->SM)
    sys   #$18              ; print SM (<-SM)
    jump  Prompt

    ;=== cmd ed ===
cmd_ed:
    move  A, #CSBUF
    move  B, #CMD_ED
    call  Strcmp            ; 0 = match
    bnze  A, cmd_cls
    
    call  CSnext            ; A <- @param
    bze   A, serror

    move  A, CSPOS          ; @fname
    move  B, #0             ; RD
    sys   #$50              ; open file (A <- fref)
    move  D, A              ; D = fref
    sys   #$52              ; read file (->SM)
    move  A, D              ; A = fref
    sys   #$51              ; close file
    
    move  A, CSPOS          ; @fname
    sys   #$16              ; start editor (<-SM)
    jump  Input

    ;=== cmd cls ===
cmd_cls:
    move  A, #CSBUF
    move  B, #CMD_CLS
    call  Strcmp            ; 0 = match
    bnze  A, cmd_mv
    
    sys   #$10              ; clear screen
    jump  Prompt

    ;=== cmd mv ===
cmd_mv:
    move  A, #CSBUF
    move  B, #CMD_MV
    call  Strcmp            ; 0 = match
    bnze  A, cmd_cp

    move  A, CSNUM          ; check num param
    skeq  A, #3
    jump  serror 

    call  CSnext            ; CSPOS <- @from
    move  C, CSPOS
    call  CSnext            ; CSPOS <- @to
    move  B, CSPOS
    move  A, C

    sys   #$5A              ; move file
    bze   A, ferror

    move  A, #MOVED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd cp ===
cmd_cp:
    move  A, #CSBUF
    move  B, #CMD_CP
    call  Strcmp            ; 0 = match
    bnze  A, cmd_rm

    move  A, CSNUM          ; check num param
    skeq  A, #3
    jump  serror 

    call  CSnext            ; CSPOS <- @from
    move  C, CSPOS
    call  CSnext            ; CSPOS <- @to
    move  B, CSPOS
    move  A, C

    sys   #$59              ; copy file
    bze   A, ferror

    move  A, #COPIED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd rm ===
cmd_rm:
    move  A, #CSBUF
    move  B, #CMD_RM
    call  Strcmp            ; 0 = match
    bnze  A, cmd_cd

    move  A, CSNUM          ; check num param
    skeq  A, #2
    jump  serror 

    call  CSnext            ; CSPOS <- @file
    move  A, CSPOS

    sys   #$58              ; remove file
    bze   A, ferror

    move  A, #REMOVED
    sys   #$14              ; println

    jump  Prompt

    ;=== cmd cd ===
cmd_cd:
    move  A, #CSBUF
    move  B, #CMD_CD
    call  Strcmp            ; 0 = match
    bnze  A, load_cmd

    move  A, CSNUM          ; check num param
    skeq  A, #2
    jump  serror 

    call  CSnext            ; CSPOS <- @file
    move  X, CSPOS
    move  A, [X]            ; A <- drive

    sys   #$5B              ; change dir
    bze   A, ferror

    jump  Prompt

    ;=== check for cmd file ===
load_cmd:
    ; copy cmd to BUFF2
    move  A, #BUFF2         ; @dest
    move  B, #CSBUF         ; @source
    move  C, CSLEN          ; C = max length
    inc   C                 ; consider '\0'
    call  Strcpy
    
    ; add .com extension
    move  A, #BUFF2         ; @dest
    move  B, #DCOM          ; @appendix
    move  C, #13            ; max fname length with '\0'
    call  Strcat

    ; check if file exists
    move  A, #BUFF2
    sys   #$56              ; file size (A <- size)
    bze   A, load_com       ; file does not exist
    
    ; open cmd file
    move  A, #BUFF2
    move  B, #114           ; read
    sys   #$50              ; fopen (A <- fref)

    ; read word
    move  B, A
    sys   #$5C              ; read word (A <- word)
    xchg  B, A              ; B = word, A = fref

    ; close file
    sys   #$51  
    
    ; check tag
    skne  A, #COMV1
    jump load_com

    ;=== load .com file ===
    move  A, #BUFF2         ; cmd in BUFF2
    jump  $4                ; routine resides before $100

    
    ;=== check for .com file ===
load_com:
    move  A, #CSBUF
    move  B, #DCOM
    call  Strrstr           ; check ext
    skeq  A, #1             ; com file?
    jump  load_dh16         ; try .h16

    ;=== load .com file ===
    move  A, #CSBUF         ; cmd in CSBUF
    jump  $4                ; routine resides before $100
    
    ;=== check for .h16 file ===
load_dh16:
    move  A, #CSBUF
    move  B, #DH16
    call  Strrstr           ; check ext
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
