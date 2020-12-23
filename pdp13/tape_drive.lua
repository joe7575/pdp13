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
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end

local function register_tapedrive(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	pdp13.send(pos, nil, names, "tapedrive")
end

local function formspec()
	return "size[8,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[0.5,1.0;Tape]"..
	"list[context;main;0,0.6;4,4;]"..
	"list[current_player;main;0,4.3;8,4;]"
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		if data == "on" then
			register_tapedrive(pos)
		end
		return true
	end
end

local function after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size('main', 1)
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
		return 1
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end
		if M(pos):get_int("has_power") == 1 then
			return 0
		end
		if stack:get_name() == "pdp13:tape" then
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

--minetest.register_craft({
--	output = "pdp13:tape_drive",
--	recipe = {
--		{"", "pdp13:chassis", "dye:magenta"},
--		{"", "default:copper_ingot", ""},
--		{"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", "basic_materials:plastic_sheet"},
--	},
--})

