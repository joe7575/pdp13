--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	7 segment nodes
]]--

-- for lazy programmers
local M = minetest.get_meta

local function swap_node(pos, offs, data)
	if offs == 0 and data >= 0 and data <= 16 then
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


for i = 0,16 do
	local c = string.format("%X", i)
	local groups
	if c ~= "10" then  -- off
		groups = {not_in_creative_inventory=1}
	else
		groups = {cracky=2, crumbly=2, choppy=2}
	end
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
		groups = table.copy(groups),
		on_rotate = screwdriver.disallow,
		is_ground_content = false,
		light_source = 4,
		drop = "pdp13:7segment10",
		sounds = default.node_sound_wood_defaults(),
	})

	techage.register_node({"pdp13:7segment"..c}, {
		on_recv_message = function(pos, src, topic, payload)
			if topic == "pdp13_info" then
				return {
					type = "OUT",
					help = "0..15 for the hex digit, 16 for off",
				}
			elseif topic == "pdp13_output" then
				return {
					credit = 25,
					func = swap_node,
				}
			end
		end,
	})		
end