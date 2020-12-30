--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Magnetic Tape

]]--

local MAX_SIZE = 80


local function on_use(itemstack, user)
	local meta = itemstack:get_meta()
	local data = meta:to_table().fields
	local name = data.name or ""
	local desc = data.desc or ""
	local uid = data.uid or "00000000"

	name = minetest.formspec_escape(name)
	desc = minetest.formspec_escape(desc)
	
	local formspec = "size[10,4]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"field[0.3,0.5;10,1;name;Name:;"..name.."]"..
		"textarea[0.3,1.6;10,1.8;desc;Description:;"..desc.."]"..
		"label[0,3.3;ID: "..uid.."]"..
		"button_exit[3.5,3.3;3,1;save;Save]"
	
	local player_name = user:get_player_name()
	minetest.show_formspec(player_name, "pdp13:magnetic_tape", formspec)
	return itemstack
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "pdp13:magnetic_tape" then return end
	local inv = player:get_inventory()
	local stack = player:get_wielded_item()

	if fields.save then
		local data = stack:get_meta():to_table().fields or {}
		data.name = fields.name:sub(1, MAX_SIZE)
		data.description = data.name
		data.desc = fields.desc or ""
		-- for debugging purposes
		local name = player:get_player_name()
		if minetest.check_player_privs(name, "server") then 
			if tonumber(fields.desc, 16) then
				data.uid = string.format("%08X", tonumber(fields.desc, 16))
			end
		end
		stack:get_meta():from_table({ fields = data })
	end
	player:set_wielded_item(stack)
end)

minetest.register_craftitem("pdp13:magnetic_tape", {
	description = "PDP-13 Magnetic Tape",
	inventory_image = "pdp13_magnetic_tape.png",
	groups = {book = 1, flammable = 3, pdp13_mtape = 1},
	on_use = on_use,
})

techage.recipes.add("ta3_electronic_fab", {
	output = "pdp13:magnetic_tape 1",
	input = {
		"basic_materials:plastic_strip 4", 
		"dye:dark_green 1"
	}
})
