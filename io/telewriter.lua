--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Telewriter

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local get_tbl = function(meta,key)      return minetest.deserialize(meta:get_string(key)) or {} end
local set_tbl = function(meta,key,tbl)  meta:set_string(key, minetest.serialize(tbl)) end

local Cache = {}


local function get_data(number)
	if Cache[number] then return Cache[number] end
	Cache[number] = {
		lines = {}, -- for the paper
		codes = {}, -- for the tape
	}
	return Cache[number]
end

local function format_text(data)
	local t = {}
	local start = #data.lines
	local offs = 17 - #data.lines
	for i = start, start - 16, -1 do
		local ypos = ((i + offs) * 0.4)
		if data.lines[i] then
			s = string.gsub(data.lines[i], "\t", "]label[4,"..ypos..";\027(c@#000000)")
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

local function formspec1(number)
	local data = get_data(number)
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;1;;true]"..
		"background[0,0;10,7.2;pdp13_paper_form.png]"..
		"container[0.5,-0.3]"..
		format_text(data)..
		"container_end[]"..
		"field[1,8;8,1;cmnd;;]"..
		"field_close_on_enter[cmnd;false]"
end

local function formspec2(number)
	local data = get_data(number)
	return "size[10,8.5]" ..
		"tabheader[0,0;tab;main,tape;2;;true]"..
		"list[context;main;2.5,1;1,1;]"..
		"image[2.5,1;1,1;pdp13_punched_tape.png]"..
		button("punch", "punch", data.punch, 6, 0.4)..
		button("reader", "reader", data.reader, 6, 1.6)..
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

local function write_tape(pos, number)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", 1)
	local name = stack:get_name()
	local count = stack:get_count()
	if count == 1 and name == "pdp13:tape" then
		local codes = get_data(number).codes
		if codes and #codes > 0 then
			stack = ItemStack("pdp13:tape_used")
			local meta = stack:get_meta()
			set_tbl(meta, "code", codes)
			inv:set_stack("main", 1, stack)
			return true
		end
	end
end

local function read_tape(pos, number)
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

local function printline(data, text)
	data.lines[#data.lines+1] = minetest.formspec_escape(text)
	while #data.lines > 17 do
		table.remove(data.lines, 1)
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
		M(pos):set_string("owner", placer:get_player_name())
		local own_num = techage.add_node(pos, "pdp13:telewriter")
		M(pos):set_string("node_number", own_num)
		M(pos):set_string("formspec", formspec1(own_num))
		M(pos):set_string("infotext", "PDP-13 Telewriter "..own_num)
		minetest.get_node_timer(pos):start(1)
	end,
	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		--print(dump(fields))
		local number = M(pos):get_string("node_number")
		local data = get_data(number)
		if fields.tab == "2" then
			M(pos):set_string("formspec", formspec2(number))
		elseif fields.tab == "1" then
			M(pos):set_string("formspec", formspec1(number))
		elseif fields.key_enter == "true" then
			if data.punch then -- punch to tape
				fields.cmnd = string.gsub(fields.cmnd, "\\t", "\t")
				printline(data, fields.cmnd)
				for _,val in ipairs(to_hexnumbers(fields.cmnd)) do
					data.codes[#data.codes+1] = val
				end
				M(pos):set_string("formspec", formspec1(number))
				minetest.sound_play("pdp13_telewriter", {
					pos = pos, 
					gain = 1,
					max_hear_distance = 5})
			else -- send to CPU
				data.fifo = {}
				for i = 1,#fields.cmnd do
					data.fifo[i] = string.byte(fields.cmnd, i)
				end
				data.keyboard = true
				print("send to CPU")
			end
		elseif fields.punch then
			--print(data.punch, tape_type(pos))
			if data.punch and tape_type(pos) == "pdp13:tape" then
				write_tape(pos, number)
				data.punch = false
			elseif tape_type(pos) == "pdp13:tape" then
				data.punch = true
				data.codes = {}
				minetest.get_node_timer(pos):start(1)
				if data.punch and data.reader then
					data.reader = false
				end
			end
			M(pos):set_string("formspec", formspec2(number))
		elseif fields.reader then
			if data.reader then
				data.reader = false
				printline(data, "Tape reader stopped")
			elseif tape_type(pos) == "pdp13:tape_used" then
				data.reader = true
				printline(data, "*** TELEWRITER V1.0 ***")
				printline(data, "Tape reader started")
				data.fifo = read_tape(pos, number)
				minetest.get_node_timer(pos):start(1)
				if data.punch and data.reader then
					data.punch = false
				end
			end
			M(pos):set_string("formspec", formspec2(number))
		end
	end,
	on_timer = function(pos, elapsed)
		local number = M(pos):get_string("node_number")
		local data = get_data(number)
		if data.running then
			data.running = false
			minetest.sound_play("pdp13_telewriter", {
				pos = pos, 
				gain = 1,
				max_hear_distance = 5})
		end
		if data.update then
			data.update = false
			M(pos):set_string("formspec", formspec1(number))
		end
		return true
	end,
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
	local number = M(pos):get_string("node_number")
	local data = get_data(number)
	if offs == 0 then  -- output text
		if type(value) == "table" then -- the lean variant of text output
			for i,c in ipairs(value) do 
				if c >= 128 then 
					value[i] = "." 
				else
					value[i] = string.char(c)
				end
			end
			printline(data, table.concat(value, ""))
			data.outp = {}
			data.update = true
			data.running = true
		else -- character based text output
			data.outp = data.outp or {}
			if data.punch and data.codes and #data.codes < 4096 then
				data.codes[#data.codes+1] = value
			end
			if value == 0 then
				-- should not happen
			elseif value == 10 then  -- LF
				printline(data, table.concat(data.outp, ""))
				data.outp = {}
				data.update = true
			elseif value >= 32 and value < 128 then  -- ASCII
				data.outp[#data.outp+1] = string.char(value)
			else
				data.outp[#data.outp+1] = "."
			end
			data.running = true
			if #data.outp > 64 then
				printline(data, table.concat(data.outp, ""))
				data.outp = {}
				data.update = true
			end
		end
	end
	return 0
end

local function pdp13_input(pos, offs)
	local number = M(pos):get_string("node_number")
	local data = get_data(number)
	
	if offs == 0 and (data.reader or data.keyboard) and data.fifo then
		return 1
	elseif offs == 1 and data.reader and data.fifo then
		local v = table.remove(data.fifo, 1)
		if #data.fifo == 0 then 
			data.fifo = nil 
			data.reader = false
			printline(data, "Tape reader stopped")
			M(pos):set_string("formspec", formspec2(number))
		else
			data.running = true
		end
		return v
	elseif offs == 1 and data.keyboard and data.fifo then
		local v = table.remove(data.fifo, 1)
		if #data.fifo == 0 then 
			data.fifo = nil 
			data.keyboard = false
		else
			data.running = true
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

