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

local function swap_node(pos, val)
	if val >= 0 and val <= 16 then
		local name = "pdp13:7segment"..string.format("%X", val)
		local node = minetest.get_node(pos)
		if node.name == name or string.sub(node.name, 1, 14) ~= "pdp13:7segment" then
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
		description = "PDP-13 7-Segment",
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
			"pdp13_7segment_"..c..".png^pdp13_7segment_mask.png",
		},
		after_place_node = function(pos, placer)
			pdp13.after_place_node(pos, placer, "pdp13:7segment"..c, "PDP-13 7-Segment")
			pdp13.infotext(M(pos), "PDP-13 7-Segment")
		end,
		after_dig_node = function(pos, oldnode, oldmetadata)
			pdp13.remove_node(pos, oldnode, oldmetadata)
		end,
		paramtype2 = "facedir",
		groups = table.copy(groups),
		on_rotate = screwdriver.disallow,
		is_ground_content = false,
		light_source = 4,
		drop = "pdp13:7segment10",
		sounds = default.node_sound_wood_defaults(),
		on_recv_message = function(pos, src, topic, payload)
			if pdp13.tubelib then
				pos, src, topic, payload = pos, "000", src, topic
			end
			if topic == "value" then
				payload = math.min(tonumber(payload) or 0, 16)
				swap_node(pos, payload)
			else
				return "unsupported"
			end
		end,
		on_beduino_receive_cmnd = function(pos, src, topic, payload)
			if topic == 15 then
				swap_node(pos, math.min(payload[1] or 0, 16))
				return 0
			else
				return 2
			end
		end,
	})
end

if minetest.global_exists("techage") then
	minetest.register_craft({
		output = "pdp13:7segment10",
		recipe = {
			{"wool:black", "", ""},
			{"techage:vacuum_tube", "", ""},
			{"pdp13:ic1", "", ""},
		},
	})
else
	minetest.register_craft({
		output = "pdp13:7segment10",
		recipe = {
			{"wool:black", "default:wood", ""},
			{"pdp13:ic1", "basic_materials:copper_wire", ""},
			{"", "", ""},
		},
	})
end
