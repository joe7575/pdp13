--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 tape

]]--

local MAX_SIZE = 80


local function on_use(itemstack, user)
	local meta = itemstack:get_meta()
	local data = meta:to_table().fields
	local title = data.title or ""

	local formspec = "size[8,3]" ..
		"field[0.5,1.2;7.5,0;title;Title:;" ..
			minetest.formspec_escape(title) .. "]" ..
		"button_exit[2.5,2;3,1;save;Save]"
	
	local player_name = user:get_player_name()
	minetest.show_formspec(player_name, "pdp13:tape", formspec)
	return itemstack
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "pdp13:tape" then return end
	local inv = player:get_inventory()
	local stack = player:get_wielded_item()

	if fields.save and fields.title and fields.title ~= "" then
		local data = stack:get_meta():to_table().fields or {}
		data.title = fields.title:sub(1, MAX_SIZE)
		data.description = data.title
		stack:get_meta():from_table({ fields = data })
	end
	player:set_wielded_item(stack)
end)

minetest.register_craftitem("pdp13:tape", {
	description = "PDP-13 Tape",
	inventory_image = "pdp13_punched_tape.png",
	groups = {book = 1, flammable = 3},
})

minetest.register_craftitem("pdp13:tape_used", {
	description = "PDP-13 Tape punched",
	inventory_image = "pdp13_punched_tape.png",
	groups = {book = 1, not_in_creative_inventory = 1, flammable = 3},
	stack_max = 1,
	on_use = on_use,
})

