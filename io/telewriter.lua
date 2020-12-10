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

local function formspec1(mem)
	mem.redraw = (mem.redraw or 0) + 1
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;1;;true]"..
		"label[-2,-2;"..mem.redraw.."]"..
		"background[0,0;10,7.2;pdp13_paper_form.png]"..
		"container[0.5,0.2]"..
		"style_type[label;font=mono,color=#000000]"..
		"label[0,0;\027(c@#000000)"..
		format_text(mem)..
		"]"..
		"container_end[]"..
		"field[1,8;8,1;cmnd;;]"..
		"field_close_on_enter[cmnd;false]"
end

local function formspec2(mem)
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;2;;true]"..
		"list[context;main;2.5,1;1,1;]"..
		"image[2.5,1;1,1;pdp13_punched_tape.png]"..
		button("writer", "tape -> PDP13", mem.writer, 5, 0.4)..
		button("reader", "PDP13 -> tape", mem.reader, 5, 1.6)..
		"list[current_player;main;1,4.5;8,4;]"
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

local function print_line(pos, mem, text)
	add_line(pos, mem, text)
	M(pos):set_string("formspec", formspec1(mem))
	mem.blocked = false
end

local function play_sound(pos)
	minetest.sound_play("pdp13_telewriter", {
		pos = pos, 
		gain = 1,
		max_hear_distance = 5})
end

local function has_tape(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	return minetest.get_item_group(name, "pdp13_tape") == 1
end


local function get_tape_code(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	if minetest.get_item_group(name, "pdp13_tape") == 1 then
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
	if name == "pdp13:tape" then
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
	play_sound(pos)
	minetest.after(2, function(pos)
		local mem = techage.get_nvm(pos)
		mem.writer = false
		M(pos):set_string("formspec", formspec2(mem))
	end, pos)
	local cpu_num = M(pos):get_string("cpu_number")
	local res = send_to_cpu(pos, "write_h16", code)
	local mem = techage.get_nvm(pos)
	add_line(pos, mem, "Tape to PDP13.."..(res and "ok" or "error"))
end

local function read_code_from_cpu(pos)
	play_sound(pos)
	minetest.after(2, function(pos)
		local mem = techage.get_nvm(pos)
		mem.reader = false
		M(pos):set_string("formspec", formspec2(mem))
	end, pos)
	local cpu_num = M(pos):get_string("cpu_number")
	local code = send_to_cpu(pos, "read_h16")
	local mem = techage.get_nvm(pos)
	if code then
		if write_tape_code(pos, code) then
			add_line(pos, mem, "PDP13 to tape..ok")
		else
			add_line(pos, mem, "PDP13 to tape..error")
		end
	else
		add_line(pos, mem, "PDP13 to tape..error")
	end
end

minetest.register_node("pdp13:telewriter", {
	description = "PDP-13 Telewriter",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_telewriter_top.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_side.png",
		"pdp13_telewriter_front.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16,   8/16, -6/16, 8/16 },
			{ -8/16, -6/16, -2/16,   8/16, -3/16, 8/16 },
			{ -8/16, -3/16,  3/16,   2/16,  0/16, 7/16 },
		},
	},
	on_construct = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 1)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = M(pos)
		local mem = techage.get_nvm(pos)
		meta:set_string("owner", placer:get_player_name())
		local own_num = techage.add_node(pos, "pdp13:telewriter")
		meta:set_string("node_number", own_num)
		local cpu_num = pdp13.send(pos, {"pdp13:cpu1", "pdp13:cpu1_on"}, "reg_tele", own_num)
		meta:set_string("cpu_number", cpu_num)
		meta:set_string("formspec", formspec1(mem))
		meta:set_string("infotext", "PDP-13 Telewriter "..own_num)
	end,
	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local mem = techage.get_nvm(pos)
		mem.codes = mem.codes or {}
		if fields.tab == "2" then
			M(pos):set_string("formspec", formspec2(mem))
		elseif fields.tab == "1" then
			M(pos):set_string("formspec", formspec1(mem))
--		elseif fields.key_enter == "true" then
--			if mem.punch then -- punch to tape
--				fields.cmnd = string.gsub(fields.cmnd, "\\t", "\t")
--				--printline(mem, fields.cmnd)
--				for _,val in ipairs(to_hexnumbers(fields.cmnd)) do
--					mem.codes[#mem.codes+1] = val
--				end
--				M(pos):set_string("formspec", formspec1(mem))
--				minetest.sound_play("pdp13_telewriter", {
--					pos = pos, 
--					gain = 1,
--					max_hear_distance = 5})
--			else -- send to CPU
--				mem.fifo = {}
--				for i = 1,#fields.cmnd do
--					mem.fifo[i] = string.byte(fields.cmnd, i)
--				end
--				mem.keyboard = true
--				print("send to CPU")
--			end
		elseif fields.writer and not mem.reader then
			local code = get_tape_code(pos)
			if code then
				mem.writer = true
				write_code_to_cpu(pos, code)
				M(pos):set_string("formspec", formspec2(mem))
			end
		elseif fields.reader and not mem.writer then
			if has_tape(pos) then
				mem.reader = true
				read_code_from_cpu(pos)
				M(pos):set_string("formspec", formspec2(mem))
			end
		end
	end,
	after_dig_node = function(pos, oldnode)
		techage.remove_node(pos)
	end,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

techage.register_node({"pdp13:telewriter"}, {
	on_recv_message = function(pos, src, topic, payload)
		if topic == "pdptext" then
			payload = tostring(payload) or ""
			local mem = techage.get_nvm(pos)
			if not mem.blocked then
				mem.blocked = true
				play_sound(pos)
				minetest.after(1, print_line, pos, mem, payload)
				return 1
			end
			return 0
		end
	end,
})	

minetest.register_lbm({
    label = "PDP13 unlock telewriter",
    name = "pdp13:unlock_telewriter",
    nodenames = {"pdp13:telewriter"},
    run_at_every_load = true,
    action = function(pos, node)
		local mem = techage.get_nvm(pos)
		mem.blocked = false
		mem.reader = false
		mem.writr = false
	end
})
