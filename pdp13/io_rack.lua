--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 I/O Rack

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end
local S   = function(s) return tostring(s or "-") end

local Commands = [[   PDP13 Techage I/O Commands

     OUT               IN
-----------------------------------------------
   0 - off           0 - off
   1 - on            1 - on
   2 - state         2 - running
   3 - fuel          3 - standby
   4 - load          4 - unloaded
 110 - depth       230 - off
   0 - action      999 - off
]]

Commands = Commands:gsub("\n", ",")

local Inputs = {}   -- [addr] = value
local Outputs = {}  -- [addr] = value


-- Retrieve rack number to determine the I/O address offset
local function register_at_cpu(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local cmnd = "reg_io"
	local data = {"pdp13:io_rack", "pdp13:io_rack_top"}
	local num = pdp13.send(pos, names, cmnd, data)
	if num then
		M(pos):set_int("offset", num * 8)
		return num * 8
	end
	local cpu_num = pdp13.send(pos, names, "cpu_num")
	M(pos):set_int("cpu_num", cpu_num)
end

local function register_rack_data(pos)
	local offset  = M(pos):get_int("offset")
	local cpu_num  = M(pos):get_int("cpu_num")
	local numbers = S2T(M(pos):get_int("numbers"))
	for i = 0,7 do
		pdp13.register_OutputNumber(cpu_num, i+offset, numbers[i])
		pdp13.register_AddressType(cpu_num, i+offset, "techage")
	end
end

local function formspec_power_on(pos)
	local numbers = S2T(M(pos):get_int("numbers"))
	local labels  = S2T(M(pos):get_int("labels"))
	local offset  = M(pos):get_int("offset")
	local lines = {}
	for i = 0,7 do
		local y = i * 0.8 + 1
		lines[#lines+1] = "label[0.5,"..y..";#"..S(i+offset).."]"
		lines[#lines+1] = "label[2.0,"..y..";"..S(numbers[i]).."]"
		lines[#lines+1] = "label[5.0,"..y..";"..S(Outputs[i+offset]).."]"
		lines[#lines+1] = "label[6.7,"..y..";"..S(Inputs[i+offset]).."]"
		lines[#lines+1] = "label[8.4,"..y..";"..S(labels[i]).."]"
	end
	return "size[13,10]"..
		"real_coordinates[true]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"tabheader[0,0;tab;I/O,help;1;;true]"..
		"container[0.3,1]"..
		"label[0.5,0;Addr]"..
		"label[2.0,0;Number]"..
		"label[5.0,0;OUT]"..
		"label[6.7,0;IN]"..
		"label[8.4,0;Description]"..
		table.concat(lines)..
		"container_end[]"
end

local function formspec_power_off(pos)
	local numbers = S2T(M(pos):get_int("numbers"))
	local labels  = S2T(M(pos):get_int("labels"))
	local offset  = M(pos):get_int("offset")
	local lines = {}
	for i = 0,7 do
		local y = i * 0.8 + 1
		lines[#lines+1] = "label[0.5,"..y..";#"..S(i+offset).."]"
		lines[#lines+1] = "field[2.0,"..(y-0.3)..";2.5,0.7;num"..S(i)..";;"..S(numbers[i]).."]"
		lines[#lines+1] = "label[5.0,"..y..";"..S(Outputs[i+offset]).."]"
		lines[#lines+1] = "label[6.7,"..y..";"..S(Inputs[i+offset]).."]"
		lines[#lines+1] = "field[8.4,"..(y-0.3)..";3.5,0.7;lbl"..S(i)..";;"..S(labels[i]).."]"
	end
	return "size[13,10]"..
		"real_coordinates[true]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"tabheader[0,0;tab;I/O,help;1;;true]"..
		"container[0.3,1]"..
		"background[0.2,0.5;12,6.7;pdp13_form_mask_lila.png]"..
		"label[0.5,0;Addr]"..
		"label[2.0,0;Number]"..
		"label[5.0,0;OUT]"..
		"label[6.7,0;IN]"..
		"label[8.4,0;Description]"..
		table.concat(lines)..
		"container_end[]"..
		"button[4.7,8.6;3.5,1.0;cancel;Cancel]"..
		"button[8.7,8.6;3.5,1.0;save;Save]"
end

local function formspec_help()
	return "size[13,10]"..
		"real_coordinates[true]"..
		"tabheader[0,0;tab;I/O,help;2;;true]"..
		"style_type[table;font=mono]"..
		"table[0.35,0.25;12.3,9;help;"..Commands..";1]"
end

local function pdp13_on_receive(dest_pos, src_pos, cmnd, data)
	if cmnd == "register" then
		return register_rack_data(dest_pos)
	elseif cmnd == "power" then
		M(dest_pos):set_int("has_power", data == "on" and 1 or 0)
		return true
	end
end

local function on_receive_fields(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
	
	print(dump(fields))
	if fields.tab == "2" then
		meta:set_string("formspec", formspec_help())
	elseif fields.tab == "1" then
		if M(pos):get_int("has_power") == 1 then
			meta:set_string("formspec", formspec_power_on(pos))
		else
			meta:set_string("formspec", formspec_power_off(pos))
		end
	elseif fields.quit == "true" then
		M(pos):set_int("fs_active", 0)
	end
end

local function after_place_node(pos, placer, itemstack, pointed_thing)
	local offs = register_at_cpu(pos)
	M(pos):set_string("formspec", formspec_power_off(pos))
	if offs then
		M(pos):set_string("infotext", "I/O Rack with base address "..offs)
	else
		M(pos):set_string("infotext", "I/O Rack not connected!")
	end
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	M(pos):set_int("fs_active", 1)
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1
end

minetest.register_node("pdp13:io_rack", {
	description = "PDP-13 I/O Rack",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_chassis.png^pdp13_frame.png",
	},
	after_place_node = after_place_node,
	on_receive_fields = on_receive_fields,
	on_rightclick = on_rightclick,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("pdp13:io_rack_top", {
	description = "PDP-13 I/O Rack",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_chassis.png^pdp13_frame_top.png",
	},
	after_place_node = after_place_node,
	on_receive_fields = on_receive_fields,
	on_rightclick = on_rightclick,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

pdp13.register_CommandTopic("techage", "off", 0)
pdp13.register_CommandTopic("techage", "on", 1)
pdp13.register_ResponseTopic("techage", "off", 0)
pdp13.register_ResponseTopic("techage", "on", 1)

