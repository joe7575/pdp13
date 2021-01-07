--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Punch Tape

]]--

local MAX_SIZE = 80


local function on_use(itemstack, user)
	local meta = itemstack:get_meta()
	local data = meta:to_table().fields
	local name = data.name or ""
	local desc = data.desc or ""
	local code = data.code or ""

	name = minetest.formspec_escape(name)
	desc = minetest.formspec_escape(desc)
	code = minetest.formspec_escape(code)
	
	local formspec = "size[11,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0.3,0.5;11,1;name;Name:;"..name.."]"..
		"textarea[0.3,1.6;11,1.8;desc;Description:;"..desc.."]"..
		"style_type[textarea,table;font=mono]"..
		"textarea[0.3,3.6;11,5;code;Code:;"..code.."]"..
		"button_exit[4,7.8;3,1;save;Save]"
	
	local player_name = user:get_player_name()
	minetest.show_formspec(player_name, "pdp13:punch_tape", formspec)
	return itemstack
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "pdp13:punch_tape" then return end
	local inv = player:get_inventory()
	local stack = player:get_wielded_item()

	if fields.save then
		local data = stack:get_meta():to_table().fields or {}
		data.name = fields.name:sub(1, MAX_SIZE)
		data.description = data.name
		data.desc = fields.desc or ""
		local code = fields.code or ""
		if vm16.is_ascii(code) then
			data.code = code
		else
			data.code = "<invalid ASCII>"
		end
		stack:get_meta():from_table({ fields = data })
	end
	player:set_wielded_item(stack)
end)

minetest.register_craftitem("pdp13:punch_tape", {
	description = "PDP-13 Punch Tape",
	inventory_image = "pdp13_punched_tape.png",
	groups = {book = 1, flammable = 3, pdp13_ptape = 1},
	on_use = on_use,
})

minetest.register_craft({
	output = "pdp13:punch_tape",
	recipe = {
		{"", "default:paper", "default:paper"},
		{"", "dye:yellow", "default:paper"},
		{"default:paper", "default:paper", "default:paper"},
	},
})


minetest.register_alias("pdp13:tape", "pdp13:punch_tape")
