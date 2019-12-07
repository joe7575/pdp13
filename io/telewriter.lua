--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Telewriter

]]--

-- for lazy programmers
local M = minetest.get_meta

local function hex(val)
	return string.format("%04X", val)
end

minetest.register_node("pdp13:telewriter", {
	description = "PDP-13 Telewriter",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_telewriter_top.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16,   8/16, -6/16, 8/16 },
			{ -8/16, -6/16, -2/16,   8/16, -3/16, 8/16 },
			{ -8/16, -3/16,  3/16,   2/16,  0/16, 7/16 },
		},
	},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})
