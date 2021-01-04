--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Tape chest

]]--


-- for lazy programmers
local M = minetest.get_meta

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function can_dig(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return false
	end
	local inv = M(pos):get_inventory()
	return inv:is_empty("main")
end

local function formspec()
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;main;0.5,0;8,4;]"..
	"list[current_player;main;0.5,4.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

minetest.register_node("pdp13:tape_chest", {
	description = "PDP-13 Tape Chest",
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
		"pdp13_chassis.png^pdp13_tape_chest.png^pdp13_frame.png",
		"pdp13_chassis.png^pdp13_tape_chest.png^pdp13_frame.png",
	},

	on_construct = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 32)
	end,
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("formspec", formspec())
	end,

	pdp13_on_receive = function(pos, src_pos, cmnd, data)
		if cmnd == "add_tape" then
			local inv = M(pos):get_inventory()
			local item = ItemStack(data) 
			if inv:room_for_item("main", item) then
				inv:add_item("main", item)
				return true
			end
			return false
		end
	end,
	
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	type = "shapeless",
	output = "pdp13:tape_chest",
	recipe = {"default:chest", "pdp13:chassis"}
})

