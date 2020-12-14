--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Memeory Rack

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end

local function register_memory_data(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local ram = 4
	local rom = 0
	
	if inv:get_stack("ram", 4):get_count() == 1 then
		ram = 64
	elseif inv:get_stack("ram", 3):get_count() == 1 then
		ram = 32
	elseif inv:get_stack("ram", 2):get_count() == 1 then
		ram = 16
	elseif inv:get_stack("ram", 1):get_count() == 1 then
		ram = 8
	end
		
	if inv:get_stack("rom", 4):get_count() == 1 then
		rom = 4
	elseif inv:get_stack("rom", 3):get_count() == 1 then
		rom = 3
	elseif inv:get_stack("rom", 2):get_count() == 1 then
		rom = 2
	elseif inv:get_stack("rom", 1):get_count() == 1 then
		rom = 1
	end
	
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	pdp13.send(pos, names, "memory", {ram=ram, rom=rom})
end

local function formspec()
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[0.5,1.0;RAM]"..
	"container[2,0.2]"..
	"label[0.1,0.1;4K]"..
	"label[1.1,0.1;8K]"..
	"label[2.1,0.1;16K]"..
	"label[3.1,0.1;32K]"..
	"list[context;ram;0,0.6;4,4;]"..
	"container_end[]"..
	"label[0.5,3.0;ROM]"..
	"container[2,2.2]"..
	"label[0.0,0.1;Mon.]"..
	"label[1.0,0.1;  ---]"..
	"label[2.0,0.1;  ---]"..
	"label[3.0,0.1;  ---]"..
	"list[context;rom;0,0.6;4,4;]"..
	"container_end[]"..

	"list[context;rom;2,2.8;4,4;]"..
	"list[current_player;main;0,4.3;8,4;]"
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		if data == "on" then
			register_memory_data(pos)
		end
		return true
	end
end

local function after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size('ram', 4)
	inv:set_size('rom', 4)
	meta:set_string("formspec", formspec())
end

local function can_dig(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:is_empty("ram") or not inv:is_empty("rom") then
		return false
	end
	return M(pos):get_int("has_power") ~= 1
end

minetest.register_node("pdp13:mem_rack", {
	description = "PDP-13 Memory Rack",
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
		"pdp13_chassis.png^pdp13_frame.png",
	},
	after_place_node = after_place_node,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if M(pos):get_int("has_power") == 1 then
			return 0
		end
		return  stack:get_count()
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if M(pos):get_int("has_power") == 1 then
			return 0
		end
		if listname == "ram" and index == 1 and stack:get_name() == "pdp13:ram4k" then
			return 1
		end
		if listname == "ram" and index == 2 and stack:get_name() == "pdp13:ram8k" then
			return 1
		end
		if listname == "rom" and index == 1 and stack:get_name() == "pdp13:mon_rom" then
			return 1
		end
		return 0
	end,
	
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craftitem("pdp13:chassis", {
	description = "PDP-13 Chassis Rack",
	inventory_image = "pdp13_chassis.png^pdp13_frame.png",
})

minetest.register_craft({
	output = "pdp13:chassis",
	recipe = {
		{"default:steel_ingot", "default:wood", "default:steel_ingot"},
		{"dye:black", "wool:white", "dye:black"},
		{"techage:iron_ingot", "default:wood", "techage:iron_ingot"},
	},
})

minetest.register_craft({
	output = "pdp13:io_rack",
	recipe = {
		{"", "pdp13:chassis", ""},
		{"", "default:copper_ingot", ""},
		{"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet"},
	},
})

