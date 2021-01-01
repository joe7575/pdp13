--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Tapes

]]--

local MAX_SIZE = 80

pdp13.tape = {}

local function on_use(itemstack, user)
	local name = itemstack:get_name()
	local idef = minetest.registered_craftitems[name] or {}
	local formspec = "size[11,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"style_type[label;font=mono]"..
		"label[0,0;"..idef.text.."]"..
		"button_exit[4,7.8;3,1;exit;Exit]"
	local player_name = user:get_player_name()
	minetest.show_formspec(player_name, "pdp13:demotape", formspec)
	return itemstack
end

function pdp13.tape.register_tape(name, desc, text, code, hidden)
	text = minetest.formspec_escape(text)
	minetest.register_craftitem(name, {
		description = desc,
		text = text,
		code = code,
		stack_max = 1,
		inventory_image = "pdp13_punched_tape.png",
		groups = {book = 1, flammable = 3, pdp13_ptape = 1},
		on_use = on_use})
	if not hidden then -- do not publish hidden demos
		pdp13.register_demotape(name, desc)
	end
end

