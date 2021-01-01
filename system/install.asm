; J/OS Install Tape v1.0
; Write tape to RAM and start
; program at address 0
;--------------------------------------

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
