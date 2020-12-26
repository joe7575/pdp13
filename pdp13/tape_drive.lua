--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Tape Drive

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end

local function register_tapedrive(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local cpu_pos = pdp13.send(pos, nil, names, "reg_tape", pos)
	if cpu_pos then
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
	end
end

local function has_tape(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	return minetest.get_item_group(name, "pdp13_mtape") == 1
end


local function copy_tape_to_filesystem(pos)
	local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
	local inv = M(pos):get_inventory()
	
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	if minetest.get_item_group(name, "pdp13_mtape") == 1 then
		-- test if demo tape
		local idef = minetest.registered_craftitems[name] or {}
		if idef.code then
			pdp13.set_filesystem(cpu_pos, 2, idef.code)
			return true
		end
		-- test if real tape
		local meta = stack:get_meta()
		if meta then
			local data = meta:to_table().fields
			pdp13.set_filesystem(pos, 2, data.code or "")
			return true
		end
	end
end

local function copy_filesystem_to_tape(pos)
	local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
	local inv = M(pos):get_inventory()
	
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	if stack:get_name() == "pdp13:magnetic_tape" then
		local meta = stack:get_meta()
		if meta then
			local data = meta:to_table().fields or {}
			data.code = pdp13.get_filesystem(cpu_pos, 2) or ""
			meta:from_table({ fields = data })
			inv:set_stack("main", 1, stack)
			return true
		end
	end
end

local function formspec(status)
	return "size[8,6]" ..
		"background[0.1,0.7;3.5,0.6;pdp13_form_mask.png]"..
		"style_type[label,field;font=mono]"..
		"label[0.1,0.7;"..status.."]"..
		"list[context;main;4,0.5;1,1;]"..
		"image[4,0.5;1,1;pdp13_magnetic_tape.png]"..
		"button[5.4,0.0;1.7,1;start;start]"..
		"button[5.4,1.0;1.7,1;stop;stop]"..
		"list[current_player;main;0,2.3;8,4;]"
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "register" then
		if register_tapedrive(pos) then
			M(pos):set_string("formspec", formspec("connected"))
			return true
		end
	elseif cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		if data == "on" then
			M(pos):set_string("formspec", formspec("powered"))
		else
			M(pos):set_string("formspec", formspec("no power"))
			M(pos):set_int("running", 0)
			copy_filesystem_to_tape(pos)
		end
		return true
	end
end

local function after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size('main', 1)
	meta:set_string("formspec", formspec("..."))
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	
	if M(pos):get_int("running") == 1 then
		return
	end
	
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if inv:get_stack(listname, index):get_count() > 0 then
		return 0
	end
	
	if minetest.get_item_group(stack:get_name(), "pdp13_mtape") == 1 then
		return 1
	end
	
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if M(pos):get_int("running") == 1 then
		return 0
	end
	return stack:get_count()
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	if M(pos):get_string("cpu_pos") == "" then
		return
	end
	if M(pos):get_int("has_power") ~= 1 then
		return 0
	end
	
	if fields.start and has_tape(pos) then
		M(pos):set_string("formspec", formspec("started"))
		M(pos):set_int("running", 1)
		copy_tape_to_filesystem(pos)
	elseif fields.stop then
		M(pos):set_string("formspec", formspec("stopped"))
		M(pos):set_int("running", 0)
		copy_filesystem_to_tape(pos)
	end
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1 and M(pos):get_inventory():is_empty("main")
end

minetest.register_node("pdp13:tape_drive", {
	description = "PDP-13 Tape Drive",
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.4, 0.5, 0.5, 0.4},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_chassis.png^pdp13_tapedrive.png^pdp13_frame_top.png",
	},
	after_place_node = after_place_node,
	pdp13_on_receive = pdp13_on_receive,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	can_dig = can_dig,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "pdp13:tape_drive",
	recipe = {
		{"", "pdp13:chassis", "dye:magenta"},
		{"pdp13:ic1", "basic_materials:gear_steel", "pdp13:ic1"},
		{"basic_materials:plastic_sheet", "basic_materials:motor", "basic_materials:plastic_sheet"},
	},
})

