--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP13 7 segment nodes
]]--

-- for lazy programmers
local M = minetest.get_meta

local logic = techage.logic

local function swap_node(pos, val)
	if val >= 0 and val <= 16 then
		local name = "pdp13:7segment"..string.format("%X", val)
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
		groups = {cracky=2, crumbly=2, choppy=2, not_in_creative_inventory=1}
	else
		groups = {cracky=2, crumbly=2, choppy=2}
	end
	minetest.register_node("pdp13:7segment"..c, {
		description = "PDP13 7-Segment",
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, 0.1, 0.5, 0.5, 0.5},
			},
		},
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
			logic.after_place_node(pos, placer, "pdp13:7segment"..c, "PDP13 7-Segment")
			logic.infotext(M(pos), "PDP13 7-Segment")
		end,
		after_dig_node = function(pos, oldnode, oldmetadata)
			techage.remove_node(pos, oldnode, oldmetadata)
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
			if topic == "pdp7seg" then
				payload = tonumber(payload) or 0
				swap_node(pos, payload)
			else
				return "unsupported"
			end
		end,
	})		
end