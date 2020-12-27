; Shell program for the Terminal v1.0

    jump  Start

$include "ramsize.asm"
$include "strsplit.asm"
$include "strcmp.asm"
$include "nextstr.asm"

BUFF1 = $180      ; 32 chars
BUFF2 = $1A0      ; 32 chars
BUFF3 = $1C0      ; 32 chars
BUFF4 = $1E0      ; 32 chars

MAXSTR = $40      ; max string len

Start:
    ;=== Wellcome === 
    sys   #$10              ; clear screen
    move  A, #HELLO
    sys   #$14              ; println
    move  A, #NEWLINE
    sys   #$14              ; println

    ;=== RAM size ===
    call Ramsize            ; RAM size -> A
    move  B, #10            ; base 10
    sys   #$12              ; print size
    move  A, #RAM
    sys   #$13              ; print text

    ;=== ROM size ===
    sys   #$73              ; ROM size ->A
    move  B, #10            ; base 10
    sys   #$12              ; print size
    move  A, #ROM
    sys   #$14              ; println text


    ;=== Input ===
input:
    move  A, #BUFF1
    sys   #$17              ; input string (len->A)
    nop
    bze   A, input
    inc   A                 ; no terminal?
    bze   A, input
    dec   A
    move  D, A              ; command length

    ;=== Prompt ===
    sys   #$74              ; get current drive
    sys   #$11              ; print char
    move  A, #PROMPT
    sys   #$13              ; print prompt
    move  A, #BUFF1
    sys   #$14              ; println command

    ;=== Process command ===
    move  A, #BUFF1
    move  B, #32
    call  Strsplit          ; A <- num strings
    move  C, A              ; C <- num strings
    
    ;=== cmd ls ===
    move  A, #BUFF1
    move  B, #CMD_LS
    call  Strcmp            ; 0=match
    bnze  A, exit
    move  A, #BUFF1         ; search param1
    move  B, D              ; B <- command length
    call Nextstr            ; A <- file pattern
cmd_ls:
    sys   #$57              ; list files (->SM)
    sys   #$18              ; print SM (<-SM)
    jump input

    ;=== exit ===
exit:
    move A, TEST
    sys   #$14              ; println
    halt

    
    .text
HELLO:
    "J/OS v0.1 Cold Boot\0"
NEWLINE:
    "\0"
RAM:
    " K RAM  \0"
ROM:
    " K ROM\0"
PROMPT:
    ">\0"
TEST:
    "test\0"
CMD_LS:
    "ls\0"
CMD_CAT:
    "cat\0"
