--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Telewriter
	
	I/O Addresses:
	
	offs dir description
	---- --- ------------------
	0x00 OUT output to the printer or tape
	0x01 IN  status (number of characters to read)
	0x02 IN  input  (next character from keyboard or tape)	

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local get_tbl = function(meta,key)      return minetest.deserialize(meta:get_string(key)) or {} end
local set_tbl = function(meta,key,tbl)  meta:set_string(key, minetest.serialize(tbl)) end

local IO_OUTP = 0
local IO_STS  = 1
local IO_INP  = 2

local function format_text(mem)
	local t = {}
	mem.lines = mem.lines or {}
	local start = #mem.lines
	local offs = 17 - #mem.lines
	for i = start, start - 16, -1 do
		local ypos = ((i + offs) * 0.4)
		if mem.lines[i] then
			local s = string.gsub(mem.lines[i], "\t", "]label[4,"..ypos..";\027(c@#000000)")
			t[#t+1] = "label[0,"..ypos..";\027(c@#000000)"..s.."]"
		end
	end
	return table.concat(t, "")
end

local function to_hexnumbers(s)
	local codes = {}
	for _,s in ipairs(string.split(s, " ")) do
		s = s or ""
		s = string.match(s:trim(), "^([0-9a-fA-F]+)$") or ""
		local val = tonumber(s, 16)
		if val then
			codes[#codes+1] = val
		end
	end
	return codes
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
		"container[0.5,-0.3]"..
		format_text(mem)..
		"container_end[]"..
		"field[1,8;8,1;cmnd;;]"..
		"field_close_on_enter[cmnd;false]"
end

local function formspec2(mem)
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;2;;true]"..
		"list[context;main;2.5,1;1,1;]"..
		"image[2.5,1;1,1;pdp13_punched_tape.png]"..
		button("punch", "punch", mem.punch, 6, 0.4)..
		button("reader", "reader", mem.reader, 6, 1.6)..
		"list[current_player;main;1,4.5;8,4;]"
end

local function tape_type(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	local count = stack:get_count()
	return count == 1 and name
end

local function write_tape(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	local count = stack:get_count()
	if count == 1 and name == "pdp13:tape" then
		local _,mem = pdp13.get_mem(pos)
		local codes = mem.codes or {}
		if codes and #codes > 0 then
			stack = ItemStack("pdp13:tape_used")
			local meta = stack:get_meta()
			set_tbl(meta, "code", codes)
			inv:set_stack("main", 1, stack)
			return true
		end
	end
end

local function read_tape(pos)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	local count = stack:get_count()
	if count == 1 and name == "pdp13:tape_used" then
		local meta = stack:get_meta()
		return get_tbl(meta, "code")
	end
end

local function printline(mem, text)
	mem.lines = mem.lines or {}
	text = string.gsub(text, " ", "\xE2\x80\x87")
	mem.lines[#mem.lines+1] = minetest.formspec_escape(text)
	while #mem.lines > 17 do
		table.remove(mem.lines, 1)
	end
end

local function node_timer(pos, elapsed)
	local _,mem = pdp13.get_mem(pos)
	mem.countdown = (mem.countdown or 2) - 1
	if mem.countdown > 0 then
		minetest.sound_play("pdp13_telewriter", {
			pos = pos, 
			gain = 1,
			max_hear_distance = 5})
	elseif mem.countdown == 0 then
		M(pos):set_string("formspec", formspec1(mem))
	end
	return mem.countdown > 0
end

-- ticks is 1 for a printer output
-- or more for tape punch/reader actions
local function start_timer(pos, mem, ticks)
	if not minetest.get_node_timer(pos):is_started() then
		mem.countdown = ticks + 1
		minetest.get_node_timer(pos):start(1)	
		node_timer(pos, 0)
--	else
--		mem.countdown = ticks + 1
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
		local _,mem = pdp13.init_mem(pos)
		M(pos):set_string("owner", placer:get_player_name())
		local own_num = techage.add_node(pos, "pdp13:telewriter")
		M(pos):set_string("node_number", own_num)
		M(pos):set_string("formspec", formspec1(mem))
		M(pos):set_string("infotext", "PDP-13 Telewriter "..own_num)
	end,
	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local _,mem = pdp13.get_mem(pos)
		mem.codes = mem.codes or {}
		if fields.tab == "2" then
			M(pos):set_string("formspec", formspec2(mem))
		elseif fields.tab == "1" then
			M(pos):set_string("formspec", formspec1(mem))
		elseif fields.key_enter == "true" then
			if mem.punch then -- punch to tape
				fields.cmnd = string.gsub(fields.cmnd, "\\t", "\t")
				--printline(mem, fields.cmnd)
				for _,val in ipairs(to_hexnumbers(fields.cmnd)) do
					mem.codes[#mem.codes+1] = val
				end
				M(pos):set_string("formspec", formspec1(mem))
				minetest.sound_play("pdp13_telewriter", {
					pos = pos, 
					gain = 1,
					max_hear_distance = 5})
			else -- send to CPU
				mem.fifo = {}
				for i = 1,#fields.cmnd do
					mem.fifo[i] = string.byte(fields.cmnd, i)
				end
				mem.keyboard = true
				print("send to CPU")
			end
		elseif fields.punch then
			--print(mem.punch, tape_type(pos))
			if mem.punch and tape_type(pos) == "pdp13:tape" then
				write_tape(pos)
				mem.punch = false
			elseif tape_type(pos) == "pdp13:tape" then
				mem.punch = true
				mem.codes = {}
				if mem.punch and mem.reader then
					mem.reader = false
				end
			end
			M(pos):set_string("formspec", formspec2(mem))
		elseif fields.reader then
			if mem.reader then
				mem.reader = false
				printline(mem, "Tape reader stopped")
			elseif tape_type(pos) == "pdp13:tape_used" then
				mem.reader = true
				printline(mem, "*** TELEWRITER V1.0 ***")
				printline(mem, "Tape reader started")
				mem.fifo = read_tape(pos)
				if mem.punch and mem.reader then
					mem.punch = false
				end
			end
			M(pos):set_string("formspec", formspec2(mem))
		end
	end,
	on_timer = node_timer,
	after_dig_node = function(pos, oldnode)
		--techage.power.after_dig_node(pos, oldnode)
	end,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

local function pdp13_output(pos, offs, value)
	local _,mem = pdp13.get_mem(pos)
	
	if offs == IO_OUTP then  -- output text
		if type(value) == "table" then -- the lean variant of text output
			for i,c in ipairs(value) do 
				if c >= 128 then 
					value[i] = "." 
				else
					value[i] = string.char(c)
				end
			end
			printline(mem, table.concat(value, ""))
			mem.outp = {}
			start_timer(pos, mem, 1)
		elseif type(value) == "string" then -- the even leaner variant of text output
			printline(mem, value)
			mem.outp = {}
			start_timer(pos, mem, 1)
		elseif value then -- character based text output
			mem.outp = mem.outp or {}
			if mem.punch and mem.codes and #mem.codes < 4096 then
				mem.codes[#mem.codes+1] = value
			end
			if value == 0 then
				-- should not happen
			elseif value == 10 then  -- LF
				printline(mem, table.concat(mem.outp, ""))
				mem.outp = {}
			elseif value >= 32 and value < 128 then  -- ASCII
				mem.outp[#mem.outp+1] = string.char(value)
			else
				mem.outp[#mem.outp+1] = "."
			end
			start_timer(pos, mem, 1)
			if #mem.outp > 64 then
				printline(mem, table.concat(mem.outp, ""))
				mem.outp = {}
			end
		end
	end
	return 0
end

local function pdp13_input(pos, offs)
	local _,mem = pdp13.get_mem(pos)
	
	if offs == IO_STS and (mem.reader or mem.keyboard) and mem.fifo then
		return #mem.fifo
	elseif offs == IO_INP and mem.reader and mem.fifo then
		local v = table.remove(mem.fifo, 1)
		if #mem.fifo == 0 then 
			mem.fifo = nil 
			mem.reader = false
			printline(mem, "Tape reader stopped")
			M(pos):set_string("formspec", formspec1(mem))
		else
			start_timer(pos, mem, 1)
		end
		return v
	elseif offs == 2 and mem.keyboard and mem.fifo then
		local v = table.remove(mem.fifo, 1)
		if #mem.fifo == 0 then 
			mem.fifo = nil 
			mem.keyboard = false
			M(pos):set_string("formspec", formspec1(mem))
		end
		return v
	else
		return 0
	end
end

techage.register_node({"pdp13:telewriter"}, {
	on_recv_message = function(pos, src, topic, payload)
		if topic == "pdp13_info" then
			return {
				type = "I/O",
				help = "IN: 0=state (0/1), 1=data; OUT: ?",
			}
		elseif topic == "pdp13_input" then -- from the pdp13 point of view
			return {
				credit = 5,
				func = pdp13_input,
				pos = pos,
			}
		elseif topic == "pdp13_output" then -- from the pdp13 point of view
			return {
				credit = 5,
				func = pdp13_output,
				pos = pos,
			}
		end
	end,
})	

