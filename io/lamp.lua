--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Colored signal lamp

]]--

-- for lazy programmers
local M = minetest.get_meta

local function switch_on(pos, node, color)
	if node.name == "pdp13:lamp_off" or node.name == "pdp13:lamp_on" then
		node.name = "pdp13:lamp_on"
		node.param2 = color or 0
		minetest.swap_node(pos, node)
	end
end	

local function switch_off(pos, node)
	if node.name == "pdp13:lamp_on" then
		node.name = "pdp13:lamp_off"
		node.param2 = 50
		minetest.swap_node(pos, node)
	end
end	

minetest.register_node("pdp13:lamp_off", {
    description = "PDP-13 Color Lamp",
    tiles = {"pdp13_lamp.png"},
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		pdp13.after_place_node(pos, placer, "pdp13:lamp_off", "PDP-13 Color Lamp")
		pdp13.infotext(M(pos), "PDP-13 Color Lamp")
		local node = minetest.get_node(pos)
		node.param2 = 50
		minetest.swap_node(pos, node)
	end,
	after_dig_node = function(pos, oldnode, oldmetadata)
		pdp13.remove_node(pos, oldnode, oldmetadata)
	end,
	
	on_rightclick = switch_on,

	paramtype = "light",
    paramtype2 = "color",
    palette = "pdp13_palette64.png",
	sunlight_propagates = true,
	diggable = true,
	light_source = 0,	
	drop = "pdp13:lamp_off",
	is_ground_content = false,
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_defaults(),
})


minetest.register_node("pdp13:lamp_on", {
    description = "PDP-13 Color Lamp",
    tiles = {"pdp13_lamp.png"},

	on_rightclick = switch_off,
	
	--paramtype = "light",
    paramtype2 = "color",
    palette = "pdp13_palette64.png",
	sunlight_propagates = true,
	diggable = false,
	light_source = 10,	
	is_ground_content = false,
	groups = {not_in_creative_inventory = 1},
	sounds = default.node_sound_defaults(),
})

pdp13.register_node({"pdp13:lamp_off", "pdp13:lamp_on"}, {
	on_recv_message = function(pos, src, topic, payload)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "value" then
			payload = tonumber(payload)
			local node = tubelib2.get_node_lvm(pos)
			if payload and payload > 0 then
				switch_on(pos, node, payload - 1)
			else
				switch_off(pos, node)
			end
		else
			return "unsupported"
		end
	end,
})	

minetest.register_craft({
	output = "pdp13:lamp_off",
	recipe = {
		{"wool:white", "", ""},
		{"default:mese_post_light", "", ""},
		{"pdp13:ic1", "", ""},
	},
})
