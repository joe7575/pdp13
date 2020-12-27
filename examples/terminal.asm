; Demo program for the Terminal v1.0

    ;=== Wellcome === 
    sys   #$10              ; clear screen
    move  A, #TEXT1
    sys   #$14              ; println

    ;=== RAM size ===
    move  A, #$DEAD
    move  $FFFF, A

t4k:
    move  A, $0FFF
    sub   A, #$DEAD
    bnze  A, t8k
    move  A, #4
    jump  ram_size
    
t8k:
    move  A, $1FFF
    sub   A, #$DEAD
    bnze  A, t16k
    move  A, #8
    jump  ram_size

t16k:
    move  A, $3FFF
    sub   A, #$DEAD
    bnze  A, t32k
    move  A, #16
    jump  ram_size

t32k:
    move  A, #32

ram_size:                   ; size in A
    move  B, #10            ; base 10
    sys   #$12              ; print size

    move  A, #TEXT2
    sys   #$14              ; print text

    ;=== ROM size ===
rom_size: 
    sys   #$73              ; ROM size (->A)
    move  B, #10            ; base 10
    sys   #$12              ; print size
    
    move  A, #TEXT3
    sys   #$14              ; print text

    ;=== ls tape ===
    move  A, #TEXT4
    sys   #$14              ; println

    move  A, #TEXT5         ; file name
    sys   #$57              ; list files (->SM)
    sys   #$18              ; print SM (<-SM)
    
    ;=== Prompt ===
    move  A, #TEXT6
    sys   #$14              ; println
    halt

    .text
TEXT1:
    "### Terminal Demo v1 ###\0"
TEXT2:
    " K RAM\0"
TEXT3:
    " K ROM\0"
TEXT4:
    "t$ ls\0"
TEXT5:
    "t/*\0"
TEXT6:
    "t$ _\0"
