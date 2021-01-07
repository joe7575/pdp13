; Demo program for the Terminal v1.0
; It shows how to use sys commands
; and output some info on the screen.
; This demo requires the BIOS ROM chip.
; see https://github.com/joe7575/pdp13/blob/main/examples/terminal.asm
;-----------------------------------

    ;=== Check ROM ===
    sys   #$72              ; ROM size (->A)
    sub   A, #10            ; 16K is required
    bneg  A, error
    
    ;=== Wellcome === 
    sys   #$10              ; clear screen
    move  A, #TITLE
    sys   #$14              ; println

    ;=== calc RAM size ===
    move  A, #$DEAD         ; Use this pattern...
    move  $7FFF, A          ; at last RAM addr.

t4k:
    move  A, $0FFF          ; Check if it...
    sub   A, #$DEAD         ; mirrors at $0FFF.
    bnze  A, t8k
    move  A, #4             ; 4K RAM size
    jump  ram_size
    
t8k:
    move  A, $1FFF          ; Check if it...
    sub   A, #$DEAD         ; mirrors at $1FFF.
    bnze  A, t16k
    move  A, #8             ; 8K RAM size
    jump  ram_size

t16k:
    move  A, $3FFF          ; Check if it...
    sub   A, #$DEAD         ; mirrors at $3FFF.
    bnze  A, t32k
    move  A, #16            ; 16K RAM size
    jump  ram_size

t32k:
    move  A, #32            ; 32K RAM size

ram_size:                   ; size in A
    move  B, #10            ; base 10
    sys   #$12              ; print size

    move  A, #RAM
    sys   #$13              ; print text

    ;=== read ROM size ===
rom_size: 
    sys   #$72              ; ROM size (->A)
    move  B, #10            ; base 10
    sys   #$12              ; print size
    
    move  A, #ROM
    sys   #$14              ; println text

    ;=== beep ===
    sys   #$1B

    ;=== finished ===
    move  A, #READY
    sys   #$14              ; println text
    
    halt

    ;=== force CPU exception ===
error:
    .data
    $FFFF                   ; illegal opcode

    .text
TITLE:
    "### Terminal Demo v1 ###\0"
RAM:
    "K RAM  \0"
ROM:
    "K ROM\0"
READY:
    "Ready.\0"

