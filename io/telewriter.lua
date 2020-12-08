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

--local function to_hexnumbers(s)
--	local codes = {}
--	for _,s in ipairs(string.split(s, " ")) do
--		s = s or ""
--		s = string.match(s:trim(), "^([0-9a-fA-F]+)$") or ""
--		local val = tonumber(s, 16)
--		if val then
--			codes[#codes+1] = val
--		end
--	end
--	return codes
--end

--local function button(name, label, on, x, y)
--	local img
--	if on then
--		img = "pdp13_switch_form2.png"
--	else
--		img = "pdp13_switch_form1.png"
--	end
--	return "container["..x..","..y.."]"..
--		"label[0,0.3;0]"..
--		"image_button[0.3,0;1.2,1.2;"..img..";"..name..";]"..
--		"label[1.4,0.3;1    "..label.."]"..
--		"container_end[]"
--end

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

--local function formspec2(mem)
--	return "size[10,8.5]" ..
--		"tabheader[0,0;tab;main,tape;2;;true]"..
--		"list[context;main;2.5,1;1,1;]"..
--		"image[2.5,1;1,1;pdp13_punched_tape.png]"..
--		button("punch", "punch", mem.punch, 6, 0.4)..
--		button("reader", "reader", mem.reader, 6, 1.6)..
--		"list[current_player;main;1,4.5;8,4;]"
--end

--local function tape_type(pos)
--	local inv = M(pos):get_inventory()
--	if inv:is_empty("main") then return nil end
--	local stack = inv:get_stack("main", 1)
--	local name = stack:get_name()
--	local count = stack:get_count()
--	return count == 1 and name
--end

--local function write_tape(pos)
--	local inv = M(pos):get_inventory()
--	if inv:is_empty("main") then return nil end
--	local stack = inv:get_stack("main", 1)
--	local name = stack:get_name()
--	local count = stack:get_count()
--	if count == 1 and name == "pdp13:tape" then
--		local _,mem = pdp13.get_mem(pos)
--		local codes = mem.codes or {}
--		if codes and #codes > 0 then
--			stack = ItemStack("pdp13:tape_used")
--			local meta = stack:get_meta()
--			set_tbl(meta, "code", codes)
--			inv:set_stack("main", 1, stack)
--			return true
--		end
--	end
--end

--local function read_tape(pos)
--	local inv = M(pos):get_inventory()
--	if inv:is_empty("main") then return nil end
--	local stack = inv:get_stack("main", 1)
--	local name = stack:get_name()
--	local count = stack:get_count()
--	if count == 1 and name == "pdp13:tape_used" then
--		local meta = stack:get_meta()
--		return get_tbl(meta, "code")
--	end
--end

local function printline(pos, mem, text)
	mem.lines = mem.lines or {}
	text = string.sub(text, 1, 60)
	mem.lines[#mem.lines+1] = minetest.formspec_escape(text)
	while #mem.lines > 17 do
		table.remove(mem.lines, 1)
	end
	M(pos):set_string("formspec", formspec1(mem))
	mem.blocked = false
end

local function play_sound(pos)
	minetest.sound_play("pdp13_telewriter", {
		pos = pos, 
		gain = 1,
		max_hear_distance = 5})
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
--		if minetest.is_protected(pos, player:get_player_name()) then
--			return
--		end
--		local _,mem = pdp13.get_mem(pos)
--		mem.codes = mem.codes or {}
--		if fields.tab == "2" then
--			M(pos):set_string("formspec", formspec2(mem))
--		elseif fields.tab == "1" then
--			M(pos):set_string("formspec", formspec1(mem))
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
--		elseif fields.punch then
--			--print(mem.punch, tape_type(pos))
--			if mem.punch and tape_type(pos) == "pdp13:tape" then
--				write_tape(pos)
--				mem.punch = false
--			elseif tape_type(pos) == "pdp13:tape" then
--				mem.punch = true
--				mem.codes = {}
--				if mem.punch and mem.reader then
--					mem.reader = false
--				end
--			end
--			M(pos):set_string("formspec", formspec2(mem))
--		elseif fields.reader then
--			if mem.reader then
--				mem.reader = false
--				printline(mem, "Tape reader stopped")
--			elseif tape_type(pos) == "pdp13:tape_used" then
--				mem.reader = true
--				printline(mem, "*** TELEWRITER V1.0 ***")
--				printline(mem, "Tape reader started")
--				mem.fifo = read_tape(pos)
--				if mem.punch and mem.reader then
--					mem.punch = false
--				end
--			end
--			M(pos):set_string("formspec", formspec2(mem))
--		end
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

--local function pdp13_output(pos, offs, value)
--	local _,mem = pdp13.get_mem(pos)
	
--	if offs == IO_OUTP then  -- output text
--		if type(value) == "table" then -- the lean variant of text output
--			for i,c in ipairs(value) do 
--				if c >= 128 then 
--					value[i] = "." 
--				else
--					value[i] = string.char(c)
--				end
--			end
--			printline(mem, table.concat(value, ""))
--			mem.outp = {}
--			start_timer(pos, mem, 1)
--		elseif type(value) == "string" then -- the even leaner variant of text output
--			printline(mem, value)
--			mem.outp = {}
--			start_timer(pos, mem, 1)
--		elseif value then -- character based text output
--			mem.outp = mem.outp or {}
--			if mem.punch and mem.codes and #mem.codes < 4096 then
--				mem.codes[#mem.codes+1] = value
--			end
--			if value == 0 then
--				-- should not happen
--			elseif value == 10 then  -- LF
--				printline(mem, table.concat(mem.outp, ""))
--				mem.outp = {}
--			elseif value >= 32 and value < 128 then  -- ASCII
--				mem.outp[#mem.outp+1] = string.char(value)
--			else
--				mem.outp[#mem.outp+1] = "."
--			end
--			start_timer(pos, mem, 1)
--			if #mem.outp > 64 then
--				printline(mem, table.concat(mem.outp, ""))
--				mem.outp = {}
--			end
--		end
--	end
--	return 0
--end

--local function pdp13_input(pos, offs)
--	local _,mem = pdp13.get_mem(pos)
	
--	if offs == IO_STS and (mem.reader or mem.keyboard) and mem.fifo then
--		return #mem.fifo
--	elseif offs == IO_INP and mem.reader and mem.fifo then
--		local v = table.remove(mem.fifo, 1)
--		if #mem.fifo == 0 then 
--			mem.fifo = nil 
--			mem.reader = false
--			printline(mem, "Tape reader stopped")
--			M(pos):set_string("formspec", formspec1(mem))
--		else
--			start_timer(pos, mem, 1)
--		end
--		return v
--	elseif offs == 2 and mem.keyboard and mem.fifo then
--		local v = table.remove(mem.fifo, 1)
--		if #mem.fifo == 0 then 
--			mem.fifo = nil 
--			mem.keyboard = false
--			M(pos):set_string("formspec", formspec1(mem))
--		end
--		return v
--	else
--		return 0
--	end
--end

techage.register_node({"pdp13:telewriter"}, {
	on_recv_message = function(pos, src, topic, payload)
		if topic == "pdptext" then
			payload = tostring(payload) or ""
			local mem = techage.get_nvm(pos)
			if not mem.blocked then
				mem.blocked = true
				play_sound(pos)
				minetest.after(1, printline, pos, mem, payload)
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
	end
})
