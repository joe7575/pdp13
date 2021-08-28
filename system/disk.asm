; J/OS Ouput disk ID and space
; Start from console with 'disk.h16'
; 

    .org $100
    .code
    
    move  A, B      ; com v1 tag $2001

    ;=== print info ===
    move  B, #$200  ; dest addr
    sys   #$63      ; read disk info
    move  A, #$200  ; text addr
    sys   #$14      ; println

exit:
    sys   #$71      ; warm start
