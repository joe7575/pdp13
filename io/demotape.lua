--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Demo tapes

]]--

local MAX_SIZE = 80


local function on_use(itemstack, user)
	local name = itemstack:get_name()
	local idef = minetest.registered_craftitems[name] or {}
	local formspec = "size[10,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"style_type[label;font=mono]"..
		"label[0,0;"..idef.text.."]"..
		"button_exit[3.5,7.8;3,1;exit;Exit]"
	local player_name = user:get_player_name()
	minetest.show_formspec(player_name, "pdp13:demotape", formspec)
	return itemstack
end

local function register_tape(name, desc, text, code)
	text = minetest.formspec_escape(text)
	minetest.register_craftitem(name, {
		description = desc,
		text = text,
		code = code,
		stack_max = 1,
		inventory_image = "pdp13_punched_tape.png",
		groups = {book = 1, flammable = 3, pdp13_tape = 1},
		on_use = on_use})
	if name ~= "pdp13:tapemonitor" then -- do not publish
		pdp13.register_demotape(name, desc)
	end
end

register_tape("pdp13:tape7seg", "7-Segment Demo", [[
; 7 segment demo v1.0
; PDP13 7-Segment on port #0

0000: 2010, 0081       move A, #$80    ; value command
0002: 2030, 0000       move B, #00     ; hex value

                   loop:
0004: 3030, 0001       add  B, #01
0006: 4030, 000F       and  B, #$0F    ; values from 0 to 15
0008: 6580             out #0, A
0009: 0000             nop
000A: 0000             nop
000B: 1200, 0004       jump loop
]], [[:80000002010008020300000303000014030000F
:500080065800000000012000004
:00000FF]])

register_tape("pdp13:tapecolor", "Color Lamp Demo", [[
; Color lamp demo v1.0
; PDP13 Color Lamp on port #0

0000: 2010, 0002       move A, #$80    ; value command
0002: 2030, 0000       move B, #00     ; color start value

                   loop:
0004: 4030, 003F       and  B, #$3F    ; values from 1 to 64
0006: 3030, 0001       add  B, #01
0008: 6600, 0000       out #00, A
000A: 0000             nop             ; delay
000B: 1200, 0004       jump loop
]], [[:800000020100080203000004030003F30300001
:500080066000000000012000004
:00000FF]])

register_tape("pdp13:tapetele", "Telewriter Demo", [[
; Hello world for the Telewriter v1.0

0000: 2010, 0004       move    A, #TEXT
0002: 0800             sys     #0
0003: 1C00             halt

    .text
TEXT:
    "Hello "
0004: 0048, 0065, 006C, 006C, 006F, 0020
    "World\0"
000A: 0057, 006F, 0072, 006C, 0064, 0000
]], [[:80000002010000408001C0000480065006C006C
:8000800006F00200057006F0072006C00640000
:00000FF]])

register_tape("pdp13:tapetelecolor", "Telewriter Color Demo", [[
; Input number demo v1.0
; PDP13 Color Lamp on port #0

Start:
0000: 2010, 0010       move    A, #TEXT1
0002: 0800             sys     #0

0003: 0802             sys   #2        ; read number from telewriter
0004: 5C12, FFFD       bneg  A, -3     ; val >= $8000: branch to loop

0006: 2020             move  B, A      ; number to B
0007: 2010, 0080       move  A, #$80   ; value command to A
0009: 6600, 0000       out   #00, A    ; send value to color lamp

000B: 2010, 0024       move    A, #TEXT2
000D: 0800             sys     #0

000E: 1200, 0000       jump  Start

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
]], [[:800000020100010080008025C12FFFD20202010
:800080000806600000020100024080012000000
:80010000045006E00740065007200200063006F
:8001800006C006F0072002000280031002E002E
:800200000360034002900000043006F006C006F
:6002800007200200073006500740000
:00000FF]])

register_tape("pdp13:tapemonitor", "PDP13 Monitor Program", [[
; PDP13 Monitor Program Code v1
; Use this tape to produce a PDP-13 Monitor ROM chip
; on the Fab.
]], [[:410000020F010001240000C
:81010001200104B120010581200106B12001089
:8101800120010AE120010B4698020203C30000A
:810200020407850000A30500030684020015012
:8102800FFF4200C6C20214128005032FFFB2C80
:8103000180069802050000420203C3000107810
:810380000109410000A30100007301000306800
:810400020017452FFF1200C6C20214128005032
:8104800FFFB2C801800200C6600000828004010
:8105000000F000000000000000000001240FFF4
:81058002090105E65885152FFFD1C0000480065
:8106000006C006C006F00200077006F0072006C
:81068000064000A00002090107A20B000802168
:81070005152FFFD34B000802225003F200D202C
:810780008001C0000480065006C006C006F0020
:81080000057006F0072006C0064002000320021
:8108800000020900080222C003F2010DEAD1640
:8109000FF8B215000202010DEAD1640FF9A2150
:810980000202010BEEF1640FF7F215000202010
:810A000BEEF1640FF8E21500020349000802224
:810A800003F0000200D202C08001C0060100010
:810B000660000181240FFFA600D5412FFFD2090
:810B8000040615000027412FFFC349000402004
:810C00020900040658A7412FFFD6590000A1240
:110C800FFEB
:00000FF]])
