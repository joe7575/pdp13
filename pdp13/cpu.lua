--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 CPU

]]--


local s = [[Die Maschine läuft und hat bei "echtem" Code ca. 200 MIPS. Wenn ich nur nops ausführe, sind es 450 MIPS.

Was fehlt ist eine Memory Protection:

- Daten Speicher Segment `VRAM(C, addr)   (C->ram_base + addr) & C->ram_mask)`
- Code Speicher Segment `VROM(C, addr)   (C->rom_base + addr) & C->rom_mask)`
- Shared Memory Segment `VSMEM(C, addr)   (C->smem_base + addr) & C->smem_mask)`

Damit dies mit der SMEM Maske funktioniert, muss dafür spezieller Op-Code genutzt werden.

Dazu sollte es ein ASM-Macro geben.
]]


-- for lazy programmers
local M = minetest.get_meta

local function bit(p)
  return 2 ^ (p - 1)  -- 1-based indexing
end

local function hasbit(x, p)
  return x % (p + p) >= p       
end

local function leds(address, data)
	local lLed = {}
	for i = 16,1,-1 do
		if hasbit(address, bit(17-i)) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",1.6;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if hasbit(data, bit(17-i)) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",3.0;0.4,0.4;pdp13_led_form.png]"
		end
	end
	return table.concat(lLed, "")
end

local function formspec(pos, mem)
	local sLED = leds(0x8001, 0x8001)
	local output = "d <val> (deposite)    l <addr> (load)1234567890"
	output = s
	return "size[10,7.5]"..
		--default.gui_bg..
		--default.gui_bg_img..
		--default.gui_slots..
		"background[-0.1,-0.2;10.2,5.6;pdp13_cpu_form.png]"..
		sLED..
		"label[5.2,0.9;ADDRESS]"..
		"label[5.2,2.3;DATA]"..
		
		"button[0,5.4;1.8,1;step;step]"..
		"button[0,6.2;1.8,1;dump;dump]"..
		"button[0,7.0;1.8,1;examine;examine]"..
		
		"button[1.9,5.4;1.8,1;start;start]"..
		"button[1.9,6.2;1.8,1;reset;reset]"..
		"button[1.9,7.0;1.8,1;update;update]"..
		
		"textarea[4,5.5;6.4,1.9;;;"..output.."]"..
		"background[3.8,5.6;6.2,1.5;pdp13_form_mask.png]"..
		"field[4,7.4;6.4,0.8;command;;]"..
		"field_close_on_enter[command;false]"

end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	print(dump(fields))
	M(pos):set_string("formspec", formspec(pos, mem))
end

local function on_rightclick(pos)
	local mem = tubelib2.get_mem(pos)
	M(pos):set_string("formspec", formspec(pos, mem))
end

minetest.register_node("pdp13:cpu1", {
	description = "PDP-13 CPU",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_cpu.png^pdp13_frame.png^pdp13_frame_top.png",
	},
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("pdp13:cpu1_on", {
	description = "PDP-13 CPU",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		{
			image = "pdp13_frame4.png^pdp13_cpu4.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.6,
			},
		},
	},
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	light_source = 4,
	sounds = default.node_sound_wood_defaults(),
})
