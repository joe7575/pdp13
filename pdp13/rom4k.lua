--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 4K ROM

]]--

local set_tbl = function(meta,key,tbl)  meta:set_string(key, minetest.serialize(tbl)) end
local get_tbl = function(meta,key) return minetest.deserialize(meta:get_string(key)) or {} end

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
	minetest.show_formspec(player_name, "pdp13:rom4k", formspec)
	return itemstack
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "pdp13:rom4k" then return end
	local inv = player:get_inventory()
	--local stack = player:get_wielded_item()
	local stack = ItemStack("pdp13:rom4k_burned")
	
	if fields.save and fields.title and fields.title ~= "" then
		local meta = stack:get_meta()
		local data = meta:to_table().fields or {}
		data.title = fields.title:sub(1, MAX_SIZE)
		data.description = data.title
		meta:from_table({ fields = data })
		set_tbl(meta, "code", {0x1091, 0x0000, 0x500C, 0x4412, 0xFFFF, 0x500D, 0x1140, 0x1640, 0xFFFB})
	end
	player:set_wielded_item(stack)
end)

minetest.register_craftitem("pdp13:rom4k", {
	description = "PDP-13 EPROM 4K",
	inventory_image = "pdp13_rom4k.png",
	groups = {book = 1},
	on_use = on_use,
})

minetest.register_craftitem("pdp13:rom4k_burned", {
	description = "PDP-13 EPROM 4K burned",
	inventory_image = "pdp13_rom4k.png",
	groups = {book = 1, not_in_creative_inventory = 1},
	stack_max = 1,
	on_use = function(itemstack, user)
		local meta = itemstack:get_meta()
		print(meta:get_string("description"), dump(get_tbl(meta, "code")))
		return itemstack
	end,
})
