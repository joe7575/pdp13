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
local NUM_LINES = 16+1
local STR_LEN = 64
local COLOR = "\027(c@#FFCC00)"  -- amber
local NEWLINE = "\n"..COLOR
local SCREENSAVER_TIME = 60 * 5
local WR = 119 

local function read_screenbuffer(mem)
	mem.lLines = mem.lLines or {""}
	local t, ln = mem.lLines, #mem.lLines
	if t[ln] == "" then ln = ln - 1 end
	
	-- delete old lines
	for _ = NUM_LINES, ln, 1 do
		table.remove(t, 1)
	end
	--print(table.concat(t, "\n"))
	return COLOR..table.concat(t, NEWLINE)
end

local function add_text(mem, text)
	mem.lLines = mem.lLines or {""}
	local t, ln = mem.lLines, #mem.lLines
	
	t[ln] = (t[ln] or "")..text
end

local function add_newline(mem)
	mem.lLines = mem.lLines or {""}
	local t, ln = mem.lLines, #mem.lLines
	
	t[ln] = string.sub(t[ln], 1, NUM_CHARS)
	t[ln] = minetest.formspec_escape(t[ln])
	
	t[ln+1] = ""
end

local function add_lines(mem, lines)
	mem.lLines = mem.lLines or {""}
	local t = mem.lLines
	
	add_text(mem, minetest.formspec_escape(lines[1] or ""))
	
	for i = 2, #lines do
		local line = string.sub(lines[i], 1, NUM_CHARS)
		t[#t+1] = minetest.formspec_escape(line)
	end

	t[#t+1] = ""
end

local function add_codelines(text)
	local t = {}
	for idx, line in ipairs(pdp13.text2table(text)) do
		table.insert(t, string.format("%3u: %s", idx, line))
	end
	return table.concat(t, "\n")
end

local function register_terminal(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local cpu_pos = pdp13.send(pos, nil, names,  "reg_term", pos)
	if cpu_pos then
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
		-- needed for sys commands
		local mem = pdp13.get_nvm(cpu_pos)
		mem.term_pos = pos
	end
end	

local function register_programmer(pos)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local number = M(pos):get_string("node_number")
	local cpu_num = pdp13.send(pos, nil, names,  "reg_prog", number)
	if cpu_num then
		M(pos):set_string("cpu_number", cpu_num)
		local cpu_pos = (pdp13.get_node_info(cpu_num) or {}).pos
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
	end
end	

local function formspec1(pos, mem)
	local s
	
	if mem.ttl then
		if mem.ttl > minetest.get_gametime() then
			s = read_screenbuffer(mem)
		else
			s = ""
			mem.ttl = nil
		end
	else
		return  -- screensaver
	end
	
	mem.command = mem.command or ""
	mem.redraw = (mem.redraw or 0) + 1
	M(pos):set_string("formspec", "size[11,8.5]" ..
		default.gui_bg..
		default.gui_bg_img..
		"background[-0.1,-0.2;11.2,9.15;pdp13_form_term1.png]"..
		"label[-2,-2;"..mem.redraw.."]"..
		"container[0.2,0.2]"..
		"background[0,0;10.6,6.7;pdp13_form_term2.png]"..
		"style_type[label,field;font=mono]"..
		"label[0,0;"..s.."]"..
		"container_end[]"..
		"button[0.6,7.0;1.8,1;esc;ESC]"..
		"button[2.7,7.0;1.7,1;f1;F1]"..
		"button[4.7,7.0;1.7,1;f2;F2]"..
		"button[6.7,7.0;1.7,1;f3;F3]"..
		"button[8.7,7.0;1.7,1;f4;F4]"..
		"style_type[field;textcolor=#000000]"..
		"field[0.9,8.2;7.8,0.8;command;;"..minetest.formspec_escape(mem.command).."]"..
		"button[8.7,7.8;1.7,1;enter;Enter]"..
		"field_close_on_enter[command;false]")
end

local function formspec2(pos, code)
	code = minetest.formspec_escape(code or "")
	M(pos):set_string("formspec", "size[11,8.5]" ..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"background[-0.1,-0.2;11.2,9.15;pdp13_form_term1.png]"..
		"style_type[textarea;font=mono;textcolor=#FFCC00;border=false]"..
		"textarea[0.4,0.1;10.8,9.1;text;;"..code.."]"..
		"background[0.2,0.2;10.6,7.7;pdp13_form_term2.png]"..
		"button[4.5,7.9;1.8,1;list;List]"..
		"button[6.4,7.9;1.8,1;exit;Exit]"..
		"button[8.3,7.9;1.8,1;save;Save]")
end

local function formspec3(pos, code)
	code = add_codelines(code)
	code = minetest.formspec_escape(code or "")
	M(pos):set_string("formspec", "size[11,8.5]" ..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"background[-0.1,-0.2;11.2,9.15;pdp13_form_term1.png]"..
		"style_type[textarea;font=mono;textcolor=#FFCC00;border=false]"..
		"textarea[0.4,0.1;10.8,9.1;;;"..code.."]"..
		"background[0.2,0.2;10.6,7.7;pdp13_form_term2.png]"..
		"button[4.5,7.9;1.8,1;edit;Edit]"..
		"button[6.4,7.9;1.8,1;exit;Exit]"..
		"button[8.3,7.9;1.8,1;save;Save]")
end

local function clear_screen(pos, mem)
	mem.lLines = {""}
	formspec1(pos, mem)
end

local function print_string(pos, mem, s)
	add_text(mem, s)
	formspec1(pos, mem)
end

local function print_string_ln(pos, mem, s)
	add_text(mem, s)
	add_newline(mem)
	formspec1(pos, mem)
end

local function screenbuffer_update(pos, mem, text)
	local t = {}
	for i = 1, NUM_CHARS * NUM_LINES, NUM_CHARS do
		local line = string.sub(text, i, i + NUM_CHARS)
		t[#t] = minetest.formspec_escape(line)
	end
	mem.lLines = t
	formspec1(pos, mem)
end

local function monitor_print_lines(pos, mem, lines)
	add_lines(mem, lines)
	formspec1(pos, mem)
end

local function editor_screen(pos, mem, text)
	mem.text = text
	formspec2(pos, text)
	mem.editor_active = true
end

local tiles = {
	-- up, down, right, left, back, front
	'pdp13_terminal_top.png',
	'pdp13_terminal_side.png',
	'pdp13_terminal_side.png^[transformFX',
	'pdp13_terminal_side.png',
	'pdp13_terminal_back.png',
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
	local mem = pdp13.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
	clear_screen(pos, mem)
	meta:set_string("owner", placer:get_player_name())
	local own_num = pdp13.add_node(pos, name)
	meta:set_string("node_number", own_num)  -- for techage
	meta:set_string("own_number", own_num)  -- for tubelib
end

local function on_rightclick(pos, node, clicker)
	if minetest.is_protected(pos, clicker:get_player_name()) then
		return
	end
	local mem = pdp13.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
	if mem.editor_active then
		formspec2(pos, mem.text or "")
	else
		formspec1(pos, mem)
	end
end

local function edit_save(pos, mem, text)
	if text and text ~= "" then
		local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
		if mem.fname == "" then mem.fname = "new.txt" end
		pdp13.write_file(cpu_pos, mem.fname, text)
		formspec2(pos, "File stored.")
		mem.text = text
		minetest.after(1, formspec2, pos, text)
	end
end

local function edit_list(pos, mem, text)
	mem.text = text
	formspec3(pos, text)
end
local function edit_edit(pos, mem, text)
	formspec2(pos, mem.text)
	mem.text = nil
end

local function function_keys(fields)
	if fields.esc then
		fields.command = "\027"
		fields.enter = true
	elseif fields.f1 then
		fields.command = "\028"
		fields.enter = true
	elseif fields.f2 then
		fields.command = "\029"
		fields.enter = true
	elseif fields.f3 then
		fields.command = "\030"
		fields.enter = true
	elseif fields.f4 then
		fields.command = "\031"
		fields.enter = true
	end
	return fields
end
		
local function on_receive_fields(pos, formname, fields, player)
	--print(dump(fields))
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	if M(pos):get_string("cpu_pos") == "" then
		return
	end
	if M(pos):get_int("has_power") ~= 1 then
		return
	end
	
	local mem = pdp13.get_nvm(pos)
	mem.ttl = minetest.get_gametime() + SCREENSAVER_TIME
	fields = function_keys(fields)
		
	if fields.key_enter_field or fields.enter then
		if M(pos):get_int("monitor") == 1 then
			if mem.monitor then
				local prompt, lines = pdp13.monitor(mem.cpu_pos, mem, fields.command or "", true)
				if prompt then
					print_string_ln(pos, mem, prompt)
				end
				monitor_print_lines(pos, mem, lines or {})
			end
		else
			mem.input = string.sub(fields.command or "", 1, STR_LEN)
			if mem.input == "" then
				mem.input = "\026"
			end
		end
		pdp13.historybuffer_add(pos, fields.command or "")
		mem.command = ""
		formspec1(pos, mem)
	elseif fields.key_up then
		mem.command = pdp13.historybuffer_priv(pos)
		formspec1(pos, mem)
	elseif fields.key_down then
		mem.command = pdp13.historybuffer_next(pos)
		formspec1(pos, mem)
	elseif fields.save then
		edit_save(pos, mem, fields.text)
	elseif fields.list then
		edit_list(pos, mem, fields.text)
	elseif fields.edit then
		edit_edit(pos, mem, fields.text)
	elseif fields.exit then
		mem.editor_active = nil
		print_string_ln(pos, mem, "completed.")
		local cpu_pos = S2P(M(pos):get_string("cpu_pos"))
		pdp13.sys_call(cpu_pos, pdp13.PROMPT, 0, 0)
		mem.edit = false
		mem.input = fields.command or ""
		pdp13.cpu_freeze(pos, false)
	elseif fields.quit then
		mem.ttl = 0
	end
end

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	--print("pdp13_on_receive", cmnd)
	local mem = pdp13.get_nvm(pos)
	if cmnd == "input" then
		if mem.input then
			local s = string.trim(mem.input)
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
		editor_screen(pos, mem, data.text)
		mem.fname = dUpdateata.fname
		pdp13.cpu_freeze(pos, true)
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
		local mem = pdp13.get_nvm(pos)
		mem.lLines = {""}
		if data == "on" then
			if M(pos):get_int("monitor") == 1 then
				print_string_ln(pos, mem, "PDP13 Terminal Programmer")
			else
				print_string_ln(pos, mem, "PDP13 Terminal Operator")
			end
		else
			clear_screen(pos, mem)
		end
		mem.input = nil
		mem.monitor = nil
		return true
	end
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1
end

local function after_dig_node(pos, oldnode, oldmetadata)
	pdp13.remove_node(pos, oldnode, oldmetadata)
	pdp13.remove_node(pos)
	pdp13.del_mem(pos)
end

minetest.register_node("pdp13:terminal", {
	description = "PDP-13 Terminal Operator",
	tiles = tiles,
	drawtype = "nodebox",
	node_box = node_box,
	selection_box = selection_box,
	after_place_node = function(pos, placer)
		after_place_node(pos, placer, "pdp13:terminal")
		M(pos):set_string("infotext", "PDP-13 Terminal Operator")
		M(pos):set_int("monitor", 0)
	end,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	
	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_recv_message = function(pos, src, topic, payload)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "monitor" then
			local mem = pdp13.get_nvm(pos)
			if payload then
				mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
				clear_screen(pos, mem)
				print_string_ln(pos, mem, "### Monitor v2.0 ###")
				pdp13.monitor_init(mem.cpu_pos, mem)
			elseif mem.monitor then
				print_string_ln(pos, mem, "end.")
				pdp13.monitor_stopped(mem.cpu_pos, mem, payload, true)
			end
			mem.monitor = payload
			return true
		elseif topic == "stopped" then  -- CPU stopped
			local mem = pdp13.get_nvm(pos)
			mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
			local lines = pdp13.monitor_stopped(mem.cpu_pos, mem, payload, true)
			monitor_print_lines(pos, mem, lines or {})
			return true
		end
	end,
})

minetest.register_node("pdp13:terminal_prog", {
	description = "PDP-13 Terminal Programmer",
	tiles = tiles,
	drawtype = "nodebox",
	node_box = node_box,
	selection_box = selection_box,
	after_place_node = function(pos, placer)
		after_place_node(pos, placer, "pdp13:terminal_prog")
		M(pos):set_string("infotext", "PDP-13 Terminal Programmer")
		M(pos):set_int("monitor", 1)
	end,
	on_rightclick = on_rightclick,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	
	paramtype = "light",
	use_texture_alpha = "clip",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	groups = {choppy=2, cracky=2, crumbly=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_recv_message = function(pos, src, topic, payload)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "monitor" then
			local mem = pdp13.get_nvm(pos)
			if payload then
				mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
				clear_screen(pos, mem)
				print_string_ln(pos, mem, "### Monitor v2.0 ###")
				pdp13.monitor_init(mem.cpu_pos, mem)
			elseif mem.monitor then
				print_string_ln(pos, mem, "end.")
				pdp13.monitor_stopped(mem.cpu_pos, mem, payload, true)
			end
			mem.monitor = payload
			return true
		elseif topic == "stopped" then  -- CPU stopped
			local mem = pdp13.get_nvm(pos)
			mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
			local lines = pdp13.monitor_stopped(mem.cpu_pos, mem, payload, true)
			monitor_print_lines(pos, mem, lines or {})
			return true
		end
	end,
})

if minetest.global_exists("techage") then
	minetest.register_craft({
		output = "pdp13:terminal",
		recipe = {
			{"", "techage:terminal2", ""},
			{"", "pdp13:ic1", ""},
			{"", "", ""},
		},
	})

	minetest.register_craft({
		output = "pdp13:terminal_prog",
		recipe = {
			{"", "techage:terminal2", ""},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"", "", ""},
		},
	})
else
	minetest.register_craft({
		output = "pdp13:terminal",
		recipe = {
			{"default:glass", "pdp13:ic1", "default:copper_ingot"},
			{"default:steel_ingot", "pdp13:ic1", "default:steel_ingot"},
			{"default:steel_ingot", "dye:grey", "default:steel_ingot"},
		},
	})

	minetest.register_craft({
		output = "pdp13:terminal_prog",
		recipe = {
			{"pdp13:terminal", "", ""},
			{"pdp13:ic1", "", ""},
			{"", "", ""},
		},
	})
end
