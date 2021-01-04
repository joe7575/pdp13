--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Punch Tapes

]]--

pdp13.tape.register_tape("pdp13:tape_7seg", "Demo: 7-Segment",
[[; 7 segment demo v1.0
; PDP13 7-Segment on port #0

0000: 2010, 0080    move A, #$80  ; 'value' command
0002: 2030, 0000    move B, #00   ; value in B

loop:
0004: 3030, 0001    add  B, #01
0006: 4030, 000F    and  B, #$0F  ; values from 0 to 15
0008: 6600, 0000    out #00, A    ; output to 7-segment
000A: 0000          nop           ; 100 ms delay
000B: 0000          nop           ; 100 ms delay
000C: 1200, 0004    jump loop

]], [[:20000010000000D
:80000002010008020300000303000014030000F
:6000800660000000000000012000004
:00000FF
]], false)


pdp13.tape.register_tape("pdp13:tape_color", "Demo: Color Lamp",
[[; Color lamp demo v1.0
; PDP13 Color Lamp on port #1

0000: 2010, 0080    move A, #$80  ; 'value' command
0002: 2030, 0000    move B, #00   ; value in B

loop:
0004: 4030, 003F    and  B, #$3F  ; values from 1 to 64
0006: 3030, 0001    add  B, #01
0008: 6600, 0001    out #01, A
000A: 0000          nop           ; delay
000B: 1200, 0004    jump loop

]], [[:20000010000000C
:800000020100080203000004030003F30300001
:500080066000001000012000004
:00000FF
]], false)


pdp13.tape.register_tape("pdp13:tape_tele", "Demo: Telewriter Output",
[[; Hello world for the Telewriter v1.0

0000: 2010, 0004    move    A, #TEXT
0002: 0800          sys     #0
0003: 1C00          halt

    .text
TEXT:
    "Hello "
0004: 0048, 0065, 006C, 006C, 006F, 0020
    "World\0"
000A: 0057, 006F, 0072, 006C, 0064, 0000
]], [[:20000010000000F
:80000002010000408001C0000480065006C006C
:8000800006F00200057006F0072006C00640000
:00000FF
]], false)


pdp13.tape.register_tape("pdp13:tape_inp_num", "Demo: Telewriter Input Number",
[[; Input number demo v1.0
; PDP13 Color Lamp on port #1

Start:
0000: 2010, 0010    move    A, #TEXT1
0002: 0800          sys     #0

0003: 0802          sys   #2       ; read number from telewriter
0004: 5C12, FFFD    bneg  A, -3    ; val >= $8000: branch to loop

0006: 2020          move  B, A     ; number to B
0007: 2010, 0080    move  A, #$80  ; value command to A
0009: 6600, 0001    out   #01, A   ; send value to color lamp

000B: 2010, 0024    move    A, #TEXT2
000D: 0800          sys     #0

000E: 1200, 0000    jump  Start

    .text
TEXT1:
    "Enter "
0010: 0045, 006E, 0074, 0065, 0072, 0020
    "color "
0016: 0063, 006F, 006C, 006F, 0072, 0020
    "(1..64)\0"
001C: 0028, 0031, 002E, 002E, 0036, 0034, 0029, 0000
TEXT2:
    "Color set\0"
0024: 0043, 006F, 006C, 006F, 0072, 0020, 0073, 0065, 0074, 0000
]], [[:20000010000002D
:800000020100010080008025C12FFFD20202010
:800080000806600000120100024080012000000
:80010000045006E00740065007200200063006F
:8001800006C006F0072002000280031002E002E
:800200000360034002900000043006F006C006F
:6002800007200200073006500740000
:00000FF
]], false)


pdp13.tape.register_tape("pdp13:tape_inp_str", "Demo: Telewriter Input String",
[[; Input string demo v1.0

Start:
0000: 2010, 0015    move  A, #TEXT1
0002: 0800          sys   #0        ; output text

0003: 2010, 0100    move  A, #$100
0005: 0801          sys   #1        ; read string from telewriter
0006: 5C12, FFFB    bneg  A, -5     ; val >= $8000: branch to move

0008: 2090, 0100    move  X, #$100  ; src ptr
000A: 20B0, 002D    move  Y, #TEXT3 ; dst ptr

000C: 216A          move [Y]+, [X]+ ; copy char
000D: 7412, FFFD    dbnz A, -3

000F: 212C          move [Y], #0    ; zero terminated string

0010: 2010, 0020    move  A, #TEXT2
0012: 0800          sys   #0        ; output text

0013: 1200, 0000    jump  Start

    .text
TEXT1:
    "Enter "
0015: 0045, 006E, 0074, 0065, 0072, 0020
    "text\0"
001B: 0074, 0065, 0078, 0074, 0000
TEXT2:
    "You entered: "
0020: 0059, 006F, 0075, 0020, 0065, 006E, 0074, 0065, 0072, 0065, 0064, 003A, 0020
TEXT3:
]], [[:20000010000002C
:80000002010001508002010010008015C12FFFB
:80008002090010020B0002D216A7412FFFD212C
:8001000201000200800120000000045006E0074
:800180000650072002000740065007800740000
:80020000059006F007500200065006E00740065
:5002800007200650064003A0020
:00000FF
]], false)


pdp13.tape.register_tape("pdp13:tape_terminal", "Demo: Terminal",
[[; Demo program for the Terminal v1.0
; It shows how to use sys commands
; and output some info on the screen.
; This demo requires the BIOS ROM chip.
; see https://github.com/joe7575/pdp13/blob/main/examples/terminal.asm
]], [[:20000010000006D
:800000008723410000A5C10003F081020100040
:800080008142010DEAD22207FFF20110FFF3410
:8001000DEAD50100017201000041200002D2011
:80018001FFF3410DEAD50100021201000081200
:8002000002D20113FFF3410DEAD5010002B2010
:800280000101200002D201000202030000A0812
:800300020100059081308732030000A08122010
:800380000610814081B2010006708141C00FFFF
:80040000023002300230020005400650072006D
:80048000069006E0061006C002000440065006D
:8005000006F0020007600310020002300230023
:80058000000004B002000520041004D00200020
:80060000000004B00200052004F004D00000052
:60068000065006100640079002E0000
:00000FF
]], false)
