; J/OS Shell2 v1.0
; Second part of the cmnd shell
; File name: shell2.com
;--------------------------------------
; Loaded as application and later
; Will be replaced by a .com file.

; checkext ext next_lbl
$macro checkext 2
    move  A, #cmdstr.BUF    ; A <- @cmd
    move  B, #%1            ; B <- @ext
    call  strrstr           ; check ext
    skeq  A, #1             ; match?
    jump  %2                ; try next
$endmacro

; addext ext next_lbl
; (and check if file exists)
$macro addext 2
    ; split old ext
    move  X, #cmdstr.BUF2   ; A <- @dest
    add   X, cmdstr.LEN
    move  [X], #0
    ; add new ext
    move  A, #cmdstr.BUF2   ; A <- @dest
    move  B, #%1            ; B <- @ext
    move  C, #13            ; max fname length with '\0'
    call  strcat

    ; check if file exists
    move  A, #cmdstr.BUF2
    sys   #$7C              ; file exists (A <- res)
    bze   A, %2             ; file does not exist
$endmacro



    .org $100
    .code

    move  A, B              ; com v1 tag $2001
    
Prompt:
    ;=== Prompt 1 ===
    sys   #$1A              ; output prompt

    ;=== Input ===
Input:
    move  A, #cmdstr.BUF
    sys   #$17              ; input string (a <- len)
    move  cmdstr.LEN, A     ; command length
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
exe_cmd:
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
    bnze  A, cmd_cpn

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

    ;=== cmd cpn ===
cmd_cpn:
    move  A, #cmdstr.BUF
    move  B, #CMD_CPN
    call  strcmp            ; 0 = match
    bnze  A, cmd_rm

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #3
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @from
    move  C, cmdstr.POS
    call  cmdstr.next       ; cmdstr.POS <- @to
    move  B, cmdstr.POS     ; B <- @to
    move  A, C              ; A <- @from

    sys   #$62              ; get files (>pipe)
    bze   A, ferror

    move  A, B              ; A <- @to
    call  cpyfiles          ; copy files (<pipe)
    bze   A, ferror

    move  B, #10            ; base
    sys   #$12              ; print num
    
    move  A, #32            ; blank
    sys   #$11              ; print char
    
    move  A, #COPIED2
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
    bnze  A, cmd_mkdir

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #2
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @dir
    move  A, cmdstr.POS

    sys   #$5D              ; change dir
    bze   A, ferror

    jump  Prompt

    ;=== cmd mkdir ===
cmd_mkdir:
    move  A, #cmdstr.BUF
    move  B, #CMD_MKDIR
    call  strcmp            ; 0 = match
    bnze  A, cmd_rmdir

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #2
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @dir
    move  A, cmdstr.POS     ; A <- dir

    sys   #$60              ; make dir
    bze   A, ferror

    jump  Prompt

    ;=== cmd rmdir ===
cmd_rmdir:
    move  A, #cmdstr.BUF
    move  B, #CMD_RMDIR
    call  strcmp            ; 0 = match
    bnze  A, load_com

    move  A, cmdstr.NUM     ; check num param
    skeq  A, #2
    jump  serror 

    call  cmdstr.next       ; cmdstr.POS <- @dir
    move  X, cmdstr.POS     ; A <- dir

    sys   #$61              ; remove dir
    bze   A, ferror

    jump  Prompt

    ;=== check for .com file ===
load_com:
    checkext DCOM load_bat

    ; load .com file
    move  A, #cmdstr.BUF    ; cmd in cmdstr.BUF
    jump  $4                ; routine resides before $100

    ;=== check for .bat file ===
load_bat:
    checkext DBAT load_h16

    ; load .bat file
    move  A, #cmdstr.BUF    ; cmd in cmdstr.BUF
    jump exe_bat

    ;=== check for .h16 file ===
load_h16:
    checkext DH16 load_cmd

    ;=== load .h16 file ===
    move  A, #cmdstr.BUF
    jump  $0C               ; routine resides before $100

    ;=== check for .com/.bat files ===
load_cmd:
    ; copy cmd to BUFF2
    move  A, #cmdstr.BUF2   ; @dest
    move  B, #cmdstr.BUF    ; @source
    move  C, cmdstr.LEN     ; C = max length
    inc   C                 ; consider '\0'
    call  strcpy

    ; check for .com
test_com:
    addext DCOM test_bat

    ; load .com file
    move  A, #cmdstr.BUF2   ; fname in cmdstr.BUF2
    jump  $4                ; routine resides before $100
    
    ; check for .bat
test_bat:
    addext DBAT serror

    ; load .bat file
    move  A, #cmdstr.BUF2   ; fname in cmdstr.BUF2
    jump exe_bat
    
    ;=== error ===
serror:
    move  A, #SERROR
    sys   #$14              ; println
    jump  Prompt

ferror:
    move  A, #FERROR
    sys   #$14              ; println
    jump  Prompt

    ;=== load and exe bat file ===
exe_bat:
    ; load .bat
    sys   #$7B              ; load bat (pipe <- text)
    bze   A, ferror

    ; read file line
    move  A, #cmdstr.BUF   ; A = dest
    sys   #$81             ; read line (<pipe)
    bze   A, ferror
    
    jump  exe_cmd           ; restart shell


  
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
CMD_CPN:
    "cpn\0"
CMD_RM:
    "rm\0"
CMD_CD:
    "cd\0"
CMD_MKDIR:
    "mkdir\0"
CMD_RMDIR:
    "rmdir\0"
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
COPIED2:
    "Files copied\0"
DCOM:
    ".com\0"
DH16:
    ".h16\0"
DBAT:
    ".bat\0"

$include "cmdstr.asm"
$include "strstrip.asm"
$include "strsplit.asm"
$include "strcmp.asm"
$include "nextstr.asm"
$include "strrstr.asm"
$include "strcpy.asm"
$include "strcat.asm"
$include "less.asm"
$include "cpyfiles.asm"
