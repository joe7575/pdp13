--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Text Terminal

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local NUM_CHARS = 48
local NUM_LINES = 16
local STR_LEN = 64
local COLOR = "\027(c@#FFCC00)"  -- amber
local NEWLINE = "\n"..COLOR
local NUM_COLOR = string.len(COLOR)
local SCREENSAVER_TIME = 60 * 5

local function trim_text(text)
	local t = {}
	for s in text:gmatch("[^\n]+") do
		table.insert(t, s)
	end
	-- delete first line
	if #t > (NUM_LINES + 1) then
		table.remove(t, 1)
	end
	-- cut line length
	t[#t] = string.sub(t[#t], 1, NUM_CHARS + NUM_COLOR)
	return table.concat(t, "\n")
end

local function register_terminal(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local cpu_pos = pdp13.send(pos, nil, names,  "reg_term", pos)
	if cpu_pos then
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
		-- needed for sys commands
		local mem = techage.get_nvm(cpu_pos)
		mem.term_pos = pos
	end
end	

local function register_programmer(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local number = M(pos):get_string("node_number")
	local cpu_num = pdp13.send(pos, nil, names,  "reg_prog", number)
	if cpu_num then
		M(pos):set_string("cpu_number", cpu_num)
		local cpu_pos = (techage.get_node_info(cpu_num) or {}).pos
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
	end
end	

local function formspec1(pos, mem)
	local s
	
	if mem.ttl then
		if mem.ttl > minetest.get_gametime() then
			s = minetest.formspec_escape(mem.screen_buffer or COLOR)
		else
			s = ""
			mem.ttl = nil
		end
	else
		return  -- screensaver
	end
	
	print("redraw")
	mem.redraw = (mem.redraw or 0) + 1
	M(pos):set_string("formspec", "size[10,8.5]" ..
		default.gui_bg..
		default.gui_bg_img..
		"background[-0.1,-0.2;10.2,9.15;pdp13_form_term1.png]"..
		"label[-2,-2;"..mem.redraw.."]"..
		"container[0.2,0.2]"..
		"background[0,0;9.6,6.7;pdp13_form_term2.png]"..
		"style_type[label;font=mono]"..
		"label[0,0;"..s.."]"..
		"container_end[]"..
		"style_type[label;font=normal]"..
		"button[0.1,7.0;1.8,1;exc;ESC]"..
		"button[2.2,7.0;1.7,1;f1;F1]"..
		"button[4.2,7.0;1.7,1;f2;F2]"..
		"button[6.2,7.0;1.7,1;f3;F3]"..
		"button[8.2,7.0;1.7,1;f4;F4]"..
		"field[0.4,8.2;7.8,0.8;command;;]"..
		"button[8.2,7.8;1.7,1;enter;Enter]"..
		"field_close_on_enter[command;false]")
end

local function formspec2(code)
	code = minetest.formspec_escape(code or "")
	return "size[10,8.5]" ..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"style_type[textarea;font=mono]"..
		"textarea[0.3,0;10,9.3;edit;;"..code.."]"..
		"button_exit[5.4,7.9;1.8,1;exit;Exit]"..
		"button[7.3,7.9;1.8,1;save;Save]"
end

local function clear_screen(pos, mem)
	mem.screen_buffer = COLOR
	formspec1(pos, mem)
end

local function print_string(pos, mem, s)
	mem.screen_buffer = mem.screen_buffer..s
	--formspec1(pos, mem)
end

local function print_string_ln(pos, mem, s)
	mem.screen_buffer = trim_text(mem.screen_buffer..s..NEWLINE)
	formspec1(pos, mem)
end

local function screenbuffer_update(pos, mem, text)
	local t = {}
	for i = 1, NUM_CHARS * NUM_LINES, NUM_CHARS do
		local line = string.sub(text, i, i + NUM_CHARS)
		table.insert(t, line)
	end
	mem.screen_buffer = COLOR..table.concat(t, NEWLINE)
	formspec1(pos, mem)
end

local function monitor_print_lines(pos, mem, lines)
	for _,line in ipairs(lines or {}) do
		mem.screen_buffer = trim_text(mem.screen_buffer..line..NEWLINE)
	end
	formspec1(pos, mem)
end

local function editor_screen(pos, mem, text)
	mem.screen_buffer = COLOR
	M(pos):set_string("formspec", formspec2(text))
end

local tiles = {
	-- up, down, right, left, back, front
	'techage_terminal2_top.png',
	'techage_terminal2_side.png',
	'techage_terminal2_side.png^[transformFX',
	'techage_terminal2_side.png',
	'techage_terminal2_back.png',
	"pdp13_terminal_front.png",
}

local node_box = {
	type = "fixed",
	fixed = {
		{-12/32, -16/32, -16/32,  12/32, -14/32, 16/32},
		{-12/32, -14/32,  -3/32,  12/32,   6/32, 16/32},
		{-10/32, -12/32,  14/32,  10/32,   4/32, 18/32},
		{-12/32,   4/32,  -4/32,  12/32,   6/32, 16/32},
		{-12/32, -16/32,  -4/32, -10/32,   6/32, 16/32},
		{ 10/32, -16/32,  -4/32,  12/32,   6/32, 16/32},
		{-12/32, -14/32,  -4/32,  12/32, -12/32, 16/32},
	}
}

local selection_box = {
	type = "fixed",
	fixed = {
		{-12/32, -16/32, -4/32,  12/32, 6/32, 16/32},
	},
}

local function after_place_node(pos, placer, name)
	local meta = M(pos)
	local mem = techage.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
	clear_screen(pos, mem)
	meta:set_string("owner", placer:get_player_name())
	local own_num = techage.add_node(pos, name)
	meta:set_string("node_number", own_num)
end

local function on_rightclick(pos)
	local mem = techage.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
	formspec1(pos, mem)
end

local function on_receive_fields(pos, formname, fields, player)
	print(dump(fields))
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	if M(pos):get_string("cpu_pos") == "" then
		return
	end
	if M(pos):get_int("has_power") ~= 1 then
		return
	end
	
	local mem = techage.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
		
	if fields.key_enter_field or fields.enter then
		if M(pos):get_int("monitor") == 1 then
			print("monitor")
			local prompt, lines = pdp13.monitor(mem.cpu_pos, mem, fields.command or "", true)
			if prompt then
				print_string_ln(pos, mem, prompt)
			end
			monitor_print_lines(pos, mem, lines or {})
		else
			print("terminal")
			mem.input = string.sub(fields.command or "", 1, STR_LEN)
		end
	elseif fields.save then
		print("edit save")
		pdp13.edit_save(mem.cpu_pos, mem, fields.edit)
	elseif fields.exit then
		print("edit exit")
		local s = pdp13.edit_exit(mem.cpu_pos, mem, fields.edit)
		print_string_ln(pos, mem, s)
		mem.edit = false
		mem.input = fields.command or ""
	elseif fields.esc then
		mem.input = "\027"
	elseif fields.f1 then
		mem.input = "\028"
	elseif fields.f2 then
		mem.input = "\029"
	elseif fields.f3 then
		mem.input = "\030"
	elseif fields.f4 then
		mem.input = "\031"
	elseif fields.quit then
		mem.ttl = 0
	end
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	--print("pdp13_on_receive", cmnd)
	local mem = techage.get_nvm(pos)
	if cmnd == "input" then
		if mem.input then
			local s = mem.input
			mem.input = nil
			return s
		end
	elseif cmnd == "println" then
		print_string_ln(pos, mem, data)
		return 1
	elseif cmnd == "clear" then
		clear_screen(pos, mem)
		return 1
	elseif cmnd == "print" then
		print_string(pos, mem, data)
		return 1
	elseif cmnd == "update" then
		screenbuffer_update(pos, mem, data)
		return 1
	elseif cmnd == "edit" then
		editor_screen(pos, mem, data)
		return 1
	elseif cmnd == "register" then
		if M(pos):get_int("monitor") == 1 then
			register_programmer(pos)
		else
			register_terminal(pos)
		end
		return true
	elseif cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		local mem = techage.get_nvm(pos)
		if data == "on" then
			print_string_ln(pos, mem, "PDP13 Terminal")
		else
			clear_screen(pos, mem)
		end
		mem.input = nil
		return true
	end
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1
end

local function after_dig_node(pos, oldnode, oldmetadata)
	techage.remove_node(pos, oldnode, oldmetadata)
	techage.remove_node(pos)
	techage.del_mem(pos)
end

minetest.register_node("pdp13:terminal", {
	description = "PDP13 Terminal Operator",
	tiles = tiles,
	drawtype = "nodebox",
	node_box = node_box,
	selection_box = selection_box,
	after_place_node = function(pos, placer)
		after_place_node(pos, placer, "pdp13:terminal")
		M(pos):set_string("infotext", "PDP13 Terminal Operator")
		M(pos):set_int("monitor", 0)
	end,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("pdp13:terminal_prog", {
	description = "PDP13 Terminal Programmer",
	tiles = tiles,
	drawtype = "nodebox",
	node_box = node_box,
	selection_box = selection_box,
	after_place_node = function(pos, placer)
		after_place_node(pos, placer, "pdp13:terminal_prog")
		M(pos):set_string("infotext", "PDP13 Terminal Programmer")
		M(pos):set_int("monitor", 1)
	end,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

-- For monitor mode
techage.register_node({"pdp13:terminal", "pdp13:terminal_prog"}, {
	on_recv_message = function(pos, src, topic, payload)
		print("on_recv_message", topic)
		if topic == "monitor" then
			local mem = techage.get_nvm(pos)
			if payload then
				mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
				clear_screen(pos, mem)
				print_string_ln(pos, mem, "### Monitor v2.0 ###")
			elseif mem.monitor then
				print_string_ln(pos, mem, "end.")
			end
			mem.monitor = payload
			return true
		elseif topic == "stopped" then  -- CPU stopped
			local mem = techage.get_nvm(pos)
			mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
			print_string_ln(pos, mem, "stopped")
			return true
		end
	end,
})	

