--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	7 segment nodes
]]--

-- for lazy programmers
local M = minetest.get_meta

for i = 0,15 do
	local c = string.format("%X", i)
	minetest.register_node("pdp13:7segment"..c, {
		description = "7-Segment",
		tiles = {
			-- up, down, right, left, back, front
			"pdp13_7segment_side.png",
			"pdp13_7segment_side.png",
			"pdp13_7segment_side.png",
			"pdp13_7segment_side.png",
			"pdp13_7segment_side.png",
			"pdp13_7segment_"..c..".png",
		},
		paramtype2 = "facedir",
		groups = {cracky=2, crumbly=2, choppy=2},
		on_rotate = screwdriver.disallow,
		is_ground_content = false,
		light_source = 4,
		sounds = default.node_sound_wood_defaults(),
	})
end