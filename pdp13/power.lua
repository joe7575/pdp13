--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Power module

]]--

-- for lazy programmers
local M = minetest.get_meta

local function register_command(pos)
	pdp13.publish(pos, pdp13.AllNodes, "register")
end

local function power_command(pos, data)
	pdp13.publish(pos, pdp13.AllNodes, "power", data)
end
	
local function formspec(pos, on)
	local button = "image_button[0.5,0.6;1,1;pdp13_form_mask_off.png;button;on]"
	if on then
		button = "image_button[0.5,0.6;1,1;pdp13_form_mask_on.png;button;off]"
	end
	return "size[2,1.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0.5,0;Power]"..
		button
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	if fields.button == "on" then
		swap_node(pos, "pdp13:power1_on")
		register_command(pos)
		power_command(pos, "on")
		M(pos):set_string("formspec", formspec(pos, true))
	end
	if fields.button == "off" then
		swap_node(pos, "pdp13:power1")
		power_command(pos, "off")
		M(pos):set_string("formspec", formspec(pos, false))
	end
end

minetest.register_node("pdp13:power1", {
	description = "PDP-13 Power Module",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_power_back.png",
		"pdp13_power.png^pdp13_frame.png",
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		M(pos):set_string("formspec", formspec(pos, false))
	end,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})


minetest.register_node("pdp13:power1_on", {
	description = "PDP-13 Power Module",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_power_back.png",
		"pdp13_power_on.png^pdp13_frame.png",
	},
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	
	paramtype2 = "facedir",
	diggable = false,
	groups = {not_in_creative_inventory=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})
