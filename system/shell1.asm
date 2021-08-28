; J/OS Shell1 v1.0
; First part of the cmnd shell
; File name: shell1.h16
;--------------------------------------
; Resides below address $100
; Stays in memory as file loader

    .org 0
    jump coldstart

    .org 2
    jump warmstart

    .org 4
    ;=== load .com file ===
    sys   #$76              ; load .com file
    move  SP, #0
    jump  $100              ; start of program on $100

    .org $0C
    ;=== load .h16 file ===
    sys   #$75              ; load .h16 file
    move  SP, #0
    jump  $100              ; start of program on $100

coldstart:
    ;=== Wellcome === 
    sys   #$10              ; clear screen
    move  A, #HELLO
    sys   #$14              ; println
    move  A, #NEWLINE
    sys   #$14              ; println

    ;=== RAM size ===
    sys   #$73              ; RAM size ->A
    move  B, #10            ; base 10
    sys   #$12              ; print size
    move  A, #RAM
    sys   #$13              ; print text

    ;=== ROM size ===
    sys   #$72              ; ROM size ->A
    move  B, #10            ; base 10
    sys   #$12              ; print size
    move  A, #ROM
    sys   #$14              ; println text

    ;=== load 2. part ===
warmstart:    
    move  A, #SHELL2
    sys   #$76              ; load .com file
    bze   A, error
    jump  $100

error:
    move  A, #ERROR
    sys   #$14              ; println text
    halt

    .ctext
HELLO:
    "J/OS v0.2 Cold Boot\0"
ERROR:
    "Load error!\0"
RAM:
    " K RAM  \0"
ROM:
    " K ROM\0"

    .text
NEWLINE:
    "\0"
SHELL2:
    "shell2.com\0"

$include "cmdstr.asm"
