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

local function format_text(mem)
	local t = {}
	mem.lines = mem.lines or {}
	for i = 1, 17 - #mem.lines do
		t[#t+1] = " "
	end
	for i = 1, #mem.lines do
		t[#t+1] = "\027(c@#FFCC00)"..mem.lines[i]
	end
	return table.concat(t, "\n")
end

local function formspec1(pos, mem)
	mem.redraw = (mem.redraw or 0) + 1
	local mon = M(pos):get_int("monitor") == 1
	return "size[10,8.5]" ..
		"label[-2,-2;"..mem.redraw.."]"..
		"container[0.2,0.2]"..
		"bgcolor[#000000;false]"..
		"style_type[label;font=mono]"..
		"label[0,0;"..format_text(mem).."]"..
		"container_end[]"..
		"style_type[label;font=normal]"..
		"field[2.6,8;5.4,0.8;command;;]"..
		"button[7.94,7.6;1.7,1;enter;enter]"..
		"field_close_on_enter[command;false]"
end

local function formspec2(mem)
	return "size[10,8.5]" ..
		"label[-2,-2;"..mem.redraw.."]"..
		"bgcolor[#000000;false]"..
		"container[0.2,0.2]"..
		"style_type[label;font=mono]"..
		"label[0,0;"..format_text(mem).."]"..
		"container_end[]"..
		"style_type[label;font=normal]"..
		"field[2.6,8;5.4,0.8;command;;]"..
		"button[7.94,7.6;1.7,1;enter;enter]"..
		"field_close_on_enter[command;false]"
end

local function send_to_cpu(pos, topic, payload)
	local own_num = M(pos):get_string("node_number")
	local cpu_num = M(pos):get_string("cpu_number")
	--print("send_to_cpu", own_num, cpu_num, topic, #(payload or {}))
	return techage.send_single(own_num, cpu_num, topic, payload)
end
	
local function add_line(pos, mem, text)
	mem.lines = mem.lines or {}
	text = string.sub(text, 1, 60)
	mem.lines[#mem.lines+1] = minetest.formspec_escape(text)
	while #mem.lines > 17 do
		table.remove(mem.lines, 1)
	end
end

-- print lines to screen
local function print_lines(pos, mem, lines)
	for _, line in ipairs(lines) do
		add_line(pos, mem, line)
	end
	M(pos):set_string("formspec", formspec1(pos, mem))
end

local function register_terminal(_type, description, command)
	local name = "pdp13:terminal".._type
	minetest.register_node(name, {
		description = description,
		tiles = {
			-- up, down, right, left, back, front
			'techage_terminal2_top.png',
			'techage_terminal2_side.png',
			'techage_terminal2_side.png^[transformFX',
			'techage_terminal2_side.png',
			'techage_terminal2_back.png',
			"pdp13_terminal_front.png",
		},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-12/32, -16/32, -16/32,  12/32, -14/32, 16/32},
				{-12/32, -14/32,  -3/32,  12/32,   6/32, 16/32},
				{-10/32, -12/32,  14/32,  10/32,   4/32, 18/32},
				{-12/32,   4/32,  -4/32,  12/32,   6/32, 16/32},
				{-12/32, -16/32,  -4/32, -10/32,   6/32, 16/32},
				{ 10/32, -16/32,  -4/32,  12/32,   6/32, 16/32},
				{-12/32, -14/32,  -4/32,  12/32, -12/32, 16/32},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-12/32, -16/32, -4/32,  12/32, 6/32, 16/32},
			},
		},
		
		after_place_node = function(pos, placer)
			local meta = M(pos)
			local mem = techage.get_nvm(pos)
			meta:set_string("owner", placer:get_player_name())
			local own_num = techage.add_node(pos, name)
			meta:set_string("node_number", own_num)
			local cpu_num = pdp13.send(pos, {"pdp13:cpu1", "pdp13:cpu1_on"}, command, own_num)
			meta:set_string("cpu_number", cpu_num)
			local cpu_pos = (techage.get_node_info(cpu_num) or {}).pos
			meta:set_string("cpu_pos", P2S(cpu_pos))
			meta:set_string("formspec", formspec1(pos, mem))
			if cpu_num then
				meta:set_string("infotext", description..": Connected")
			else
				meta:set_string("infotext", description..": Not connected!")
			end
		end,

		on_receive_fields = function(pos, formname, fields, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return
			end
			local mem = techage.get_nvm(pos)
			mem.codes = mem.codes or {}
			if fields.key_enter_field or fields.enter then
				if M(pos):get_int("monitor") == 1 then
					local lines = pdp13.monitor(mem.cpu_pos, mem, fields.command or "")
					print_lines(pos, mem, lines)
				else
					print_lines(pos, mem, {fields.command or ""})
					mem.input = fields.command or ""
				end
			elseif fields.clear then
				mem.lines = {}
				M(pos):set_string("formspec", formspec1(pos, mem))
			end
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata)
			techage.remove_node(pos, oldnode, oldmetadata)
			techage.remove_node(pos)
			techage.del_mem(pos)
		end,
		
		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "facedir",
		groups = {choppy=2, cracky=2, crumbly=2},
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
	})
end

register_terminal("", "PDP13 Terminal Operator", "reg_term")
register_terminal("prog", "PDP13 Terminal Programmer", "reg_prog")

