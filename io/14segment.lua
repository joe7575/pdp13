--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP13 14-segment node
]]--

-- for lazy programmers
local M = minetest.get_meta
local N = pdp13.get_nvm

local function generate_texture(code)
	local tbl = {"pdp13_segment0.png"}
    for i = 1,14 do
		if vm16.testbit(code, i-1) then
			tbl[#tbl + 1] = "pdp13_segment" .. i .. ".png"
		end
    end
    return table.concat(tbl, "^")
end

local function update_display(pos, objref)
    pos = vector.round(pos)
	local code = N(pos).code or 0
    objref:set_properties({
        textures = { generate_texture(code) },
    })
end

minetest.register_node("pdp13:14segment", {
    description = "PDP-13 14-Segment",
    inventory_image = "pdp13_segment0.png^pdp13_segment1.png^pdp13_segment2.png^pdp13_segment3.png^" .. 
		"pdp13_segment4.png^pdp13_segment5.png^pdp13_segment6.png",
    tiles = {
		-- up, down, right, left, back, front
		"pdp13_segment0.png",
		"pdp13_7segment_side.png",
		"pdp13_7segment_side.png",
		"pdp13_7segment_side.png",
		"pdp13_7segment_side.png",
		"pdp13_7segment_side.png",
	},
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "wallmounted",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.1, 0.5},
		},
	},
    light_source = 6,

    display_entities = {
        ["techage:display_entity"] = {
            depth = 0.09,
            on_display_update = update_display
        },
    },

    after_place_node = function(pos, placer)
		pdp13.after_place_node(pos, placer, "pdp13:14segment", "PDP-13 7-Segment")
		pdp13.infotext(M(pos), "PDP-13 14-Segment")
        lcdlib.update_entities(pos)
    end,

    after_dig_node = function(pos, oldnode, oldmetadata)
        pdp13.remove_node(pos, oldnode, oldmetadata)
    end,

    on_place = lcdlib.on_place,
    on_construct = lcdlib.on_construct,
    on_destruct = lcdlib.on_destruct,
    on_rotate = lcdlib.on_rotate,
    groups = {cracky=2, crumbly=2},
    is_ground_content = false,
    sounds = default.node_sound_glass_defaults(),
})

pdp13.register_node({"pdp13:14segment"}, {
	on_recv_message = function(pos, src, topic, payload)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "value" then
			N(pos).code = tonumber(payload) or 0
			local now = techage.SystemTime
			local mem = pdp13.get_mem(pos)
			if (mem.last_message or 0) + .5 < now then
				lcdlib.update_entities(pos)
				mem.last_message = now
			end
			return true
		else
			return "unsupported"
		end
	end,
	on_beduino_receive_cmnd = function(pos, src, topic, payload)
		if topic == 16 then
			N(pos).code = payload[1] or 0
			local now = techage.SystemTime
			local mem = pdp13.get_mem(pos)
			if (mem.last_message or 0) + .5 < now then
				lcdlib.update_entities(pos)
				mem.last_message = now
			end
			return 0
		else
			return 2
		end
	end,
})

if minetest.global_exists("techage") then
	minetest.register_craft({
		output = "pdp13:14segment",
		recipe = {
			{"wool:black", "", ""},
			{"techage:vacuum_tube", "", ""},
			{"pdp13:ic1", "pdp13:ic1", ""},
		},
	})
else
	minetest.register_craft({
		output = "pdp13:14segment",
		recipe = {
			{"wool:black", "default:wood", ""},
			{"pdp13:ic1", "basic_materials:copper_wire", ""},
			{"pdp13:ic1", "", ""},
		},
	})
end
