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
end

register_tape("pdp13:tape7seg", "7-Segment Demo", [[
; 7 segment demo v1.0
; PDP13 7-Segment on port #0

0000: 2010, 0081       move A, #$81    ; 7seg command
0002: 2030, 0000       move B, #00     ; hex value

loop:
0004: 3030, 0001       add  B, #01
0006: 4030, 000F       and  B, #$0F    ; values from 0 to 15
0008: 6580             out #0, A
0009: 0000             nop
000A: 0000             nop
000B: 1200, 0004       jump loop
]], [[:80000002010008120300000303000014030000F
:500080065800000000012000004
:00000FF]])

register_tape("pdp13:tapecolor", "Color Lamp Demo", [[
; Color lamp demo v1.0
; PDP13 Color Lamp on port #0

0000: 2010, 0002       move A, #$80    ; color command
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
