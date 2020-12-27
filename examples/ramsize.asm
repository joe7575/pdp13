;===================================
; Ramsize()
; Determine the RAM size
; Used: B 
; Result: A <- size in KWords
;===================================
    .code


Ramsize:
    move  B, $FFFF          ; store value
    move  A, #$DEAD
    move  $FFFF, A

t4k:                        ; test 4 K
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
    move  $FFFF, B          ; restore value
    ret
