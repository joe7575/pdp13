; J/OS Hello world demo with parameter output
; Start from console with 'hellow'
; 

    .org $100
    .code
    
    move  A, B      ; com v1 tag $2001

    ;=== print text ===
    move  A, #TEXT
    sys   #$14      ; println

    ;=== print params ===
    move  A, CSNUM          ; check num strings
    dec   A 
    bze   A, exit           ; no param: exit
    move  D, A              ; D <- num param

loop:
    call  CSnext            ; CSPOS <- @param
    
    move  A, CSPOS
    sys   #$14              ; println
    dbnz  D, loop           ; further param: loop
    
exit:
    sys   #$71      ; warm start

    .text
TEXT:
    "Hello "
    "World\0"

$include "../system/cmdstr.asm"
