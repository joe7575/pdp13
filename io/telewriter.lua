--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Telewriter
	
]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local DELAY = 0.5	-- time for one line
local STR_LEN = 64

local function register_telewriter(pos, cmnd)
	local names = {"pdp13:cpu1", "pdp13:cpu1_on"}
	local number = M(pos):get_string("node_number")
	local cpu_num = pdp13.send(pos, nil, names,  cmnd, number)
	if cpu_num then
		M(pos):set_string("cpu_number", cpu_num)
		local cpu_pos = (pdp13.get_node_info(cpu_num) or {}).pos
		M(pos):set_string("cpu_pos", P2S(cpu_pos))
	end
end	

local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "register" then
		if M(pos):get_int("monitor") == 1 then
			register_telewriter(pos, "reg_prog")
		else
			register_telewriter(pos, "reg_tele")
		end
		return true
	elseif cmnd == "power" then
		M(pos):set_int("has_power", data == "on" and 1 or 0)
		return true
	end
end

local DemoTapes = {}

function pdp13.register_demotape(name, desc)
	DemoTapes[#DemoTapes+1] = {name = name, desc = desc}
end


local function format_text(mem)
	local t = {}
	mem.lines = mem.lines or {}
	for i = 1, 17 - #mem.lines do
		t[#t+1] = " "
	end
	for i = 1, #mem.lines do
		t[#t+1] = "\027(c@#000000)"..mem.lines[i]
	end
	return table.concat(t, "\n")
end

local function button(name, label, on, x, y)
	local img
	if on then
		img = "pdp13_switch_form2.png"
	else
		img = "pdp13_switch_form1.png"
	end
	return "container["..x..","..y.."]"..
		"label[0,0.3;0]"..
		"image_button[0.3,0;1.2,1.2;"..img..";"..name..";]"..
		"label[1.4,0.3;1    "..label.."]"..
		"container_end[]"
end

local function formspec1(pos, mem)
	mem.redraw = (mem.redraw or 0) + 1
	local mon = M(pos):get_int("monitor") == 1
	local help = mon and "?  st(art)  s(to)p  r(ese)t  n(ext)  r(egister)  ad(dress)  d(ump)  en(ter)" or ""
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;1;;true]"..
		"label[-2,-2;"..mem.redraw.."]"..
		"background[0,0;10,7.2;pdp13_paper_form.png]"..
		"container[0.5,0.2]"..
		"style_type[label;font=mono]"..
		"label[0,0;\027(c@#000000)"..
		format_text(mem)..
		"]"..
		"container_end[]"..
		"style_type[label;font=normal]"..
		"label[0,7.2;"..help.."]"..
		"button[0.4,7.6;1.7,1;clear;clear]"..
		"field[2.6,8;5.4,0.8;command;;]"..
		"button[7.94,7.6;1.7,1;enter;enter]"..
		"field_close_on_enter[command;false]"
end

local function formspec2(mem)
	local tbl = {}
	for _,item in ipairs(DemoTapes) do
		tbl[#tbl+1] = item.desc
	end
	local items = table.concat(tbl, ",")
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;2;;true]"..
		"list[context;main;2.5,1;1,1;]"..
		"image[2.5,1;1,1;pdp13_punched_tape.png]"..
		button("writer", "tape -> PDP13", mem.writer, 5, 0.4)..
		button("reader", "PDP13 -> tape", mem.reader, 5, 1.6)..
		"dropdown[1,3.2;6.2;demotape;"..items..";1;" .. items .. "]"..
		"button[7,3.15;2,1;punch;punch]"..
		"list[current_player;main;1,4.5;8,4;]"
end

local function send_to_cpu(pos, topic, payload)
	local own_num = M(pos):get_string("node_number")
	local cpu_num = M(pos):get_string("cpu_number")
	--print("send_to_cpu", own_num, cpu_num, topic, #(payload or {}))
	return pdp13.send_single(own_num, cpu_num, topic, payload)
end
	
local function add_line(pos, mem, text)
	mem.lines = mem.lines or {}
	text = string.sub(text, 1, 60)
	mem.lines[#mem.lines+1] = minetest.formspec_escape(text)
	while #mem.lines > 17 do
		table.remove(mem.lines, 1)
	end
end

local function play_sound(pos)
	minetest.sound_play("pdp13_telewriter", {
		pos = pos, 
		gain = 1,
		max_hear_distance = 5})
end

-- print one line to paper
local function print_line(pos, mem)
	local text = table.remove(mem.OutFifo, 1)
	if text then
		add_line(pos, mem, text)
		if not mem.reader and not mem.writer then -- not on tape tab?
			M(pos):set_string("formspec", formspec1(pos, mem))
		end
		mem.reader = false
		mem.writer = false
	end
end

local function add_line_to_fifo(pos, mem, text)
	mem.OutFifo = mem.OutFifo or {}
	-- free FIFO space?
	if text and #mem.OutFifo < 16 then
		table.insert(mem.OutFifo, text)
		minetest.get_node_timer(pos):start(DELAY)
	end
end

local function add_string_to_fifo(pos, mem, text)
	mem.OutFifo = mem.OutFifo or {}
	-- free FIFO space?
	if text then
		if #mem.OutFifo == 0 then
			mem.OutFifo = {text}
		elseif #mem.OutFifo < 16 then
			mem.OutFifo[#mem.OutFifo] = (mem.OutFifo[#mem.OutFifo] or "")..text
		end
	end
end

local function add_lines_to_fifo(pos, mem, lines)
	mem.OutFifo = mem.OutFifo or {}
	for _, text in ipairs(lines or {}) do
		-- free FIFO space?
		if #mem.OutFifo < 16 then
			table.insert(mem.OutFifo, text)
		end
	end
	minetest.get_node_timer(pos):start(DELAY)
end

local function has_writable_tape(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	return stack:get_name() == "pdp13:punch_tape" or stack:get_name() == "pdp13:tape"
end

local function get_tape_name(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return "" end
	local stack = inv:get_stack("main", 1)
	return stack:get_name() or ""
end

local function get_tape_code(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	if minetest.get_item_group(name, "pdp13_ptape") == 1 then
		-- test if demo tape
		local idef = minetest.registered_craftitems[name] or {}
		if idef.code then
			return idef.code
		end
		-- test if real tape
		local meta = stack:get_meta()
		if meta then
			local data = meta:to_table().fields
			if data.code and data.code ~= "" then
				return data.code
			end
		end
	end
end

local function write_tape_code(pos, code)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	if name == "pdp13:punch_tape" or name == "pdp13:tape" then
		local meta = stack:get_meta()
		if meta then
			local data = meta:to_table().fields or {}
			data.code = code
			meta:from_table({ fields = data })
			inv:set_stack("main", 1, stack)
			return true
		end
	end
end

local function write_code_to_cpu(pos, code)
	minetest.after(1, function(pos)
		local mem = pdp13.get_nvm(pos)
		mem.writer = false
		M(pos):set_string("formspec", formspec2(mem))
	end, pos)
	local cpu_num = M(pos):get_string("cpu_number")
	local res = send_to_cpu(pos, "write_h16", code)
	local mem = pdp13.get_nvm(pos)
	add_line_to_fifo(pos, mem, "Tape to PDP13.."..(res and "ok" or "error"))
end

local function gen_demotape(pos, demotape)
	for _,item in ipairs(DemoTapes) do
		if item.desc == demotape then
			minetest.after(DELAY, function(pos, name)
				local inv = M(pos):get_inventory()
				inv:set_stack("main", 1, ItemStack(name))
				local mem = pdp13.get_nvm(pos)
				add_line_to_fifo(pos, mem, "Tape punched")
			end, pos, item.name)
			play_sound(pos)
			break
		end
	end
end

local function gen_rom_tape(pos, rom_tape)
	if has_writable_tape(pos) then
		minetest.after(DELAY, function(pos, rom_tape)
			local inv = M(pos):get_inventory()
			inv:set_stack("main", 1, ItemStack(rom_tape))
			local mem = pdp13.get_nvm(pos)
			add_line_to_fifo(pos, mem, "Tape punched")
		end, pos, rom_tape)
		play_sound(pos)
	end
end

local function read_code_from_cpu(pos)
	minetest.after(1, function(pos)
		local mem = pdp13.get_nvm(pos)
		mem.reader = false
		M(pos):set_string("formspec", formspec2(mem))
	end, pos)
	local cpu_num = M(pos):get_string("cpu_number")
	local code = send_to_cpu(pos, "read_h16")
	local mem = pdp13.get_nvm(pos)
	if code then
		if write_tape_code(pos, code) then
			add_line_to_fifo(pos, mem, "PDP13 to tape..ok")
		else
			add_line_to_fifo(pos, mem, "PDP13 to tape..error")
		end
	else
		add_line_to_fifo(pos, mem, "PDP13 to tape..error")
	end
end

local function after_place_node(pos, placer, itemstack, name, cmnd, ntype)
	local meta = M(pos)
	local inv = meta:get_inventory()
	inv:set_size('main', 1)
	local mem = pdp13.get_nvm(pos)
	meta:set_string("owner", placer:get_player_name())
	local own_num = pdp13.add_node(pos, name)
	meta:set_string("node_number", own_num)  -- for techage
	meta:set_string("own_number", own_num)  -- for tubelib
	meta:set_string("formspec", formspec1(pos, mem))
	meta:set_string("infotext", "PDP-13 Telewriter "..ntype)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if inv:get_stack(listname, index):get_count() > 0 then
		return 0
	end
	
	if minetest.get_item_group(stack:get_name(), "pdp13_ptape") == 1 then
		return 1
	end
	
	return 0
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = pdp13.get_nvm(pos)
	mem.codes = mem.codes or {}
	
	if fields.tab == "2" then
		M(pos):set_string("formspec", formspec2(mem))
		return
	elseif fields.tab == "1" then
		M(pos):set_string("formspec", formspec1(pos, mem))
		return
	end
	
	if M(pos):get_string("cpu_number") == "" then
		return
	end
	if M(pos):get_int("has_power") ~= 1 then
		return
	end
	
	if fields.key_enter_field or fields.enter then
		if M(pos):get_int("monitor") == 1 then
			local _, lines = pdp13.monitor(mem.cpu_pos, mem, fields.command or "")
			add_lines_to_fifo(pos, mem, lines)
		else
			add_line_to_fifo(pos, mem, fields.command or "")
			mem.input = string.sub(fields.command or "", 1, STR_LEN)
		end
	elseif fields.clear then
		mem.lines = {}
		M(pos):set_string("formspec", formspec1(pos, mem))
	elseif fields.writer and not mem.reader then
		local code = get_tape_code(pos)
		if code then
			mem.writer = true
			write_code_to_cpu(pos, code)
			M(pos):set_string("formspec", formspec2(mem))
		end
	elseif fields.reader and not mem.writer then
		if has_writable_tape(pos) then
			mem.reader = true
			read_code_from_cpu(pos)
			M(pos):set_string("formspec", formspec2(mem))
		end
	elseif fields.punch and not mem.writer and not mem.reader then
		if has_writable_tape(pos) then
			mem.reader = true
			gen_demotape(pos, fields.demotape)
		end
	end
end

local function node_timer(pos, elapsed)
	local mem = pdp13.get_nvm(pos)
	mem.OutFifo = mem.OutFifo or {}
	if #mem.OutFifo > 0 then
		play_sound(pos)
		print_line(pos, mem)
		return true
	end
end

local function start_tape(pos, mem)
	play_sound(pos)
	minetest.after(1, function(mem)
		mem.reader = false
		mem.writer = false
	end, mem)
end

local function can_dig(pos)
	return M(pos):get_int("has_power") ~= 1 and M(pos):get_inventory():is_empty("main")
end

local function after_dig_node(pos, oldnode, oldmetadata)
	pdp13.remove_node(pos, oldnode, oldmetadata)
	pdp13.remove_node(pos)
	pdp13.del_mem(pos)
end

local Tiles = {
	-- up, down, right, left, back, front
	"pdp13_telewriter_top.png",
	"pdp13_telewriter_side.png",
	"pdp13_telewriter_side.png",
	"pdp13_telewriter_side.png",
	"pdp13_telewriter_side.png",
	"pdp13_telewriter_front.png",
}

local Node_box = {
	type = "fixed",
	fixed = {
		{ -8.2/16, -10/16, -8.2/16,   8.2/16, -7/16, 8.2/16 },
		{ -8/16, -8/16, -2/16,   8/16, -5/16, 8/16 },
		{ -8/16, -5/16,  3/16,   2/16, -2/16, 7/16 },
	},
}

minetest.register_node("pdp13:telewriter", {
	description = "PDP-13 Telewriter Operator",
	tiles = Tiles,
	drawtype = "nodebox",
	node_box = Node_box,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_node(pos, placer, itemstack, "pdp13:telewriter", "reg_tele", "Operator")
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	on_timer = node_timer,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	paramtype = "light",
	use_texture_alpha = "clip",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_recv_message = function(pos, src, topic, payload)
		--print("on_recv_message", src, topic)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "println" then
			payload = tostring(payload) or ""
			local mem = pdp13.get_nvm(pos)
			add_line_to_fifo(pos, mem, payload)
			return 1
		elseif topic == "print" then
			payload = tostring(payload) or ""
			local mem = pdp13.get_nvm(pos)
			add_string_to_fifo(pos, mem, payload)
			return 1
		elseif topic == "input" then
			local mem = pdp13.get_nvm(pos)
			if mem.input then
				local s = string.trim(mem.input)
				mem.input = nil
				return s
			end
		elseif topic == "monitor" then
			local mem = pdp13.get_nvm(pos)
			if payload then
				mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
				add_line_to_fifo(pos, mem, "### Monitor v1.0 ###")
			elseif mem.monitor then
				add_line_to_fifo(pos, mem, "end.")
			end
			mem.monitor = payload
			return true
		elseif topic == "stopped" then  -- CPU stopped
			local mem = pdp13.get_nvm(pos)
			mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
			local lines = pdp13.monitor_stopped(mem.cpu_pos, mem, payload, false)
			add_lines_to_fifo(pos, mem, lines or {})
			return true
		elseif topic == "punch" then  -- punch "dongle" tape from exams
			local mem = pdp13.get_nvm(pos)
			mem.reader = true
			gen_rom_tape(pos, payload)
			return true
		elseif topic == "read_tape" then  -- provide the tape string
			local mem = pdp13.get_nvm(pos)
			if not mem.reader then
				mem.reader = true
				start_tape(pos, mem)
				return get_tape_code(pos)
			end			
		elseif topic == "write_tape" then  -- write string to tape
			local mem = pdp13.get_nvm(pos)
			if not mem.writer then
				if write_tape_code(pos, payload) then
					mem.writer = true
					start_tape(pos, mem)
					return 1
				end
			end			
		elseif topic == "tape_name" then
			local mem = pdp13.get_nvm(pos)
			return get_tape_name(pos)
		elseif topic == "tape_sound" then
			local mem = pdp13.get_nvm(pos)
			if not mem.reader then
				mem.reader = true
				start_tape(pos, mem)
				return 1
			end			
			return 0
		end
	end,
})

minetest.register_node("pdp13:telewriter_prog", {
	description = "PDP-13 Telewriter Programmer",
	tiles = Tiles,
	drawtype = "nodebox",
	node_box = Node_box,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		after_place_node(pos, placer, itemstack, "pdp13:telewriter_prog", "reg_prog", "Programmer")
		M(pos):set_int("monitor", 1)
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_receive_fields = on_receive_fields,
	pdp13_on_receive = pdp13_on_receive,
	on_timer = node_timer,
	can_dig = can_dig,
	after_dig_node = after_dig_node,
	paramtype = "light",
	use_texture_alpha = "clip",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_recv_message = function(pos, src, topic, payload)
		--print("on_recv_message", src, topic)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
		if topic == "println" then
			payload = tostring(payload) or ""
			local mem = pdp13.get_nvm(pos)
			add_line_to_fifo(pos, mem, payload)
			return 1
		elseif topic == "print" then
			payload = tostring(payload) or ""
			local mem = pdp13.get_nvm(pos)
			add_string_to_fifo(pos, mem, payload)
			return 1
		elseif topic == "input" then
			local mem = pdp13.get_nvm(pos)
			if mem.input then
				local s = string.trim(mem.input)
				mem.input = nil
				return s
			end
		elseif topic == "monitor" then
			local mem = pdp13.get_nvm(pos)
			if payload then
				mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
				add_line_to_fifo(pos, mem, "### Monitor v1.0 ###")
			elseif mem.monitor then
				add_line_to_fifo(pos, mem, "end.")
			end
			mem.monitor = payload
			return true
		elseif topic == "stopped" then  -- CPU stopped
			local mem = pdp13.get_nvm(pos)
			mem.cpu_pos = S2P(M(pos):get_string("cpu_pos"))
			local lines = pdp13.monitor_stopped(mem.cpu_pos, mem, payload, false)
			add_lines_to_fifo(pos, mem, lines or {})
			return true
		elseif topic == "punch" then  -- punch "dongle" tape from exams
			local mem = pdp13.get_nvm(pos)
			mem.reader = true
			gen_rom_tape(pos, payload)
			return true
		elseif topic == "read_tape" then  -- provide the tape string
			local mem = pdp13.get_nvm(pos)
			if not mem.reader then
				mem.reader = true
				start_tape(pos, mem)
				return get_tape_code(pos)
			end			
		elseif topic == "write_tape" then  -- write string to tape
			local mem = pdp13.get_nvm(pos)
			if not mem.writer then
				if write_tape_code(pos, payload) then
					mem.writer = true
					start_tape(pos, mem)
					return 1
				end
			end			
		elseif topic == "tape_name" then
			local mem = pdp13.get_nvm(pos)
			return get_tape_name(pos)
		elseif topic == "tape_sound" then
			local mem = pdp13.get_nvm(pos)
			if not mem.reader then
				mem.reader = true
				start_tape(pos, mem)
				return 1
			end			
			return 0
		end
	end,
})

minetest.register_lbm({
    label = "PDP13 unlock telewriter",
    name = "pdp13:unlock_telewriter",
    nodenames = {"pdp13:telewriter", "pdp13:telewriter_prog"},
    run_at_every_load = true,
    action = function(pos, node)
		local mem = pdp13.get_nvm(pos)
		mem.reader = false
		mem.writer = false
		mem.input = nil
	end
})

minetest.register_craft({
	output = "pdp13:telewriter",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:steel_ingot", "dye:black", "default:steel_ingot"},
		{"pdp13:ic1", "", "pdp13:ic1"},
	},
})

minetest.register_craft({
	output = "pdp13:telewriter_prog",
	recipe = {
		{"pdp13:telewriter", "", ""},
		{"pdp13:ic1", "", ""},
		{"", "", ""},
	},
})
