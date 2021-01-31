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
local S2P = minetest.string_to_pos
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
		local uid = M(pos):get_string("uid_h")
		local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
		if cpu_pos then
			uid = pdp13.set_uid(cpu_pos, "h", uid)
			M(pos):set_string("uid_h", uid)
			return true
		end
	end
end

local function after_place_node(pos, placer, itemstack)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if itemstack then
		local stack_meta = itemstack:get_meta()
		if stack_meta then
			local uid = pdp13.set_uid(pos, "h", stack_meta:get_string("uid_h"))
			M(pos):set_string("uid_h", uid)
			return
		end
	end
	local uid = pdp13.set_uid(pos, "h")
	M(pos):set_string("uid_h", uid)
end

local function preserve_metadata(pos, oldnode, oldmetadata, drops)
	local uid_h = oldmetadata and oldmetadata.uid_h
	if uid_h then
		local stack_meta = drops[1]:get_meta()
		stack_meta:set_string("uid_h", uid_h)
		stack_meta:set_string("description", "PDP-13 Hard Disk (" .. uid_h .. ")")
	end
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1
end

local function after_dig_node(pos, oldnode, oldmetadata)
	local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
	if cpu_pos then
		pdp13.get_filesystem(cpu_pos, pdp13.HDD_NUM)
	end
	pdp13.del_uid(pos, "h")
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
		"pdp13_power_back.png",
		"pdp13_chassis.png^pdp13_harddisk.png^pdp13_frame.png",
	},
	after_place_node = after_place_node,
	preserve_metadata = preserve_metadata,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "pdp13:hard_disk",
	recipe = {
		{"pdp13:ic1", "pdp13:chassis", "pdp13:ic1"},
		{"pdp13:ram4k", "basic_materials:gold_wire", "pdp13:tape_hdd"},
		{"basic_materials:plastic_sheet", "basic_materials:motor", "basic_materials:plastic_sheet"},
	},
})

