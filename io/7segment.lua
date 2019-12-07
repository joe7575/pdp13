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

local function swap_node(pos, offs, data)
	if offs == 0 and data >= 0 and data < 16 then
		local name = "pdp13:7segment"..string.format("%X", data)
		local node = minetest.get_node(pos)
		if node.name == name then
			return 0
		end
		node.name = name
		minetest.swap_node(pos, node)
		return 1
	end
end


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
		after_place_node = function(pos, placer)
			local mem = tubelib2.init_mem(pos)
			local meta = minetest.get_meta(pos)
			local number = techage.add_node(pos, "pdp13:7segment"..c)
			meta:set_string("node_number", number)
			meta:set_string("infotext", "7-Segment "..number)
		end,
		after_dig_node = function(pos, oldnode, oldmetadata)
			techage.remove_node(pos)
			tubelib2.del_mem(pos)
		end,
		paramtype2 = "facedir",
		groups = {cracky=2, crumbly=2, choppy=2},
		on_rotate = screwdriver.disallow,
		is_ground_content = false,
		light_source = 4,
		sounds = default.node_sound_wood_defaults(),
	})

	techage.register_node({"pdp13:7segment"..c}, {
		on_recv_message = function(pos, src, topic, payload)
			if topic == "pdp13_output" then
				return {
					credit = 25,
					func = swap_node,
					data = "0..15",
				}
			end
		end,
	})		
end