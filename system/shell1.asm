; J/OS Shell1 v1.0
; Copy file to Tape Drive
; File name: shell1.h16
;--------------------------------------
; Resides below address $100
BUFF1 = $00C0     ; 64 chars

    .org 0
    jump coldstart

    .org 2
    jump warmstart

    .org 4
    ;=== load .com file ===
    move  A, #BUFF1
    sys   #$76              ; load .com file
    move  SP, #0
    jump  $100              ; start of program on $100

    .org $0C
    ;=== load .h16 file ===
    move  A, #BUFF1
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

    .text
HELLO:
    "J/OS v0.1 Cold Boot\0"
NEWLINE:
    "\0"
RAM:
    " K RAM  \0"
ROM:
    " K ROM\0"
SHELL2:
    "t/shell2.com\0"
ERROR:
    "Shell load error!\0"
