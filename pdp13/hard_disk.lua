--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Hard Disk

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end

local function register_harddisk(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local cpu_pos = pdp13.send(pos, nil, names, "reg_hdd", pos)
	if cpu_pos then
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
	end
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "register" then
		register_harddisk(pos)
		return true
	elseif cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		return true
	end
end

local function after_place_node(pos, placer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1
end

minetest.register_node("pdp13:hard_disk", {
	description = "PDP-13 Hard Disk",
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
		"pdp13_chassis.png^pdp13_harddisk.png^pdp13_frame.png",
	},
	after_place_node = after_place_node,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "pdp13:hard_disk",
	recipe = {
		{"", "pdp13:chassis", ""},
		{"pdp13:ic1", "basic_materials:gold_wire", "pdp13:ic1"},
		{"basic_materials:plastic_sheet", "basic_materials:motor", "basic_materials:plastic_sheet"},
	},
})

