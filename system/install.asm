; J/OS Install Tape v1.0
; Write tape to RAM and start
; program at address 0
;--------------------------------------

    .org 0
    jump Coldstart

    .org 2
    ;=== Ready ====
    move  A, #READY
    sys   #$14              ; println

    halt

;=== h16com ===
; Convert .h16 file to .com format.
h16com:
    move  A, #CSBUF
    move  B, #H16COM_FILE
    move  C, #64
    call  Strcpy

    move  A, #CSBUF
    move  B, #SHELL2_FILE2
    move  C, #64
    call  Strcat

    ;=== load tool ===
    move  A, #CSBUF
    sys   #$75              ; load .h16 file
    move  SP, #0
    jump  $100              ; start of program on $100

    .text
READY:
    "Ready.\0"

;=====================================================
    .code
    .org $100
Coldstart:
    sys   #$10              ; clear screen
    move  A, #HELLO
    sys   #$14              ; println
    move  A, #NEWLINE
    sys   #$14              ; println

    ;=== boot ====
boot:
    move  A, #BOOT_MSG
    sys   #$14              ; println
    call  readenter
    sys   #3                ; read tape (A <- 1)
    move  B, #1             ; error #1
    bze   A, error
    move  A, #BOOT_FILE
    call  writefile

    ;=== h16com ====
h16com:
    move  A, #H16COM_MSG
    sys   #$14              ; println
    call  readenter
    sys   #3                ; read tape (A <- 1)
    move  B, #2             ; error #2
    bze   A, error
    move  A, #H16COM_FILE
    call  writefile

    ;=== shell1 ====
shell1:
    move  A, #SHELL1_MSG
    sys   #$14              ; println
    call  readenter
    sys   #3                ; read tape (A <- 1)
    move  B, #3             ; error #3
    bze   A, error
    move  A, #SHELL1_FILE
    call  writefile

    ;=== shell2 ====
shell2:
    move  A, #SHELL2_MSG
    sys   #$14              ; println
    call  readenter
    sys   #3                ; read tape (A <- 1)
    move  B, #4             ; error #4
    bze   A, error
    move  A, #SHELL2_FILE
    call  writefile
    jump  h16com            ; convert to .com


;===================================
; Function: readenter
; Loop until enter is pressed.
; Param A: -
; Used   : A
; Result : -
;===================================
readenter:    
    move  A, #CSBUF
    sys   #$17              ; input string (a <- len)
    move  CSLEN, A          ; command length
    nop
    bze   A, readenter
    inc   A                 ; no terminal?
    bze   A, readenter
    move  A, #CSBUF
    skeq   A, #26
    jump  readenter

    ret

;===================================
; Function: writefile
; Convert write SM to file.
; Param A: @fname
; Used   : B
; Result : -
;===================================
writefile:
    ; open cmd file
    move  B, #119           ; write
    sys   #$50              ; fopen (A <- fref)
    move  B, #20            ; error #20
    bze   A, error
    ; write file
    move  B, A
    sys   #$54              ; write file (A <- 1)
    move  B, #21            ; error #21
    bze   A, error
    ; close file
    move  A, B              ; A = fref
    sys   #$51  
    ret
    

;===================================
; Function: error
; Output error and halt.
; Param B: error number
; Used   : -
; Result : -
;===================================
error:
    move  A, #ERROR
    sys   #$13              ; print
    move  A, B
    move  B, #10
    sys   #$12              ; print num
    move  A, #NEWLINE
    sys   #$14              ; println

    halt


    .text
HELLO:
    "J/OS Install v0.1\0"
NEWLINE:
    "\0"

BOOT_MSG:
    "Insert System Tape 'boot' and press enter\0"
BOOT_FILE:
    "boot\0"

H16COM_MSG:   
    "Insert System Tape 'h16com' and press enter\0"
H16COM_FILE:
    "h16com.h16\0"

SHELL1_MSG:   
    "Insert System Tape 'shell1' and press enter\0"
SHELL1_FILE:
    "shell1.h16\0"

SHELL2_MSG:   
    "Insert System Tape 'shell2' and press enter\0"
SHELL2_FILE:
    "shell2.h16\0"
SHELL2_FILE2:
    " shell2\0"     ; file as param w/o ext
    

ERROR:
    "Error \0"
    
$include "../system/cmdstr.asm"
$include "strcpy.asm"
$include "strcat.asm"
