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
local get_tbl = function(pos,key)      return minetest.deserialize(M(pos):get_string(key)) or {} end
local set_tbl = function(pos,key,tbl)  M(pos):set_string(key, minetest.serialize(tbl)) end

local Cache = {}


local function get_data(number)
	if Cache[number] then return Cache[number] end
	Cache[number] = {
		lines = {"0000: 0000 ; nop", "0000: 0000 ; nop"},
		codes = {},
	}
	return Cache[number]
end

local function escape_line(s)
	local s1, s2 = unpack(string.split(s, ";"))
	s1 = string.trim(minetest.formspec_escape(s1) or "")
	s2 = string.trim(minetest.formspec_escape(s2) or "")
	if s2 ~= "" then s2 = "\\; "..s2 end
	return s1, string.gsub(s2, " ", "   ")
end

local function format_text(lines)
	local t = {}
	local s1, s2
	local start = #lines
	local offs = 17 - #lines
	for i = start, start - 16, -1 do
		local ypos = ((i + offs) * 0.4) - 0.3
		if lines[i] then
			s1, s2 = escape_line(lines[i])
		else
			s1, s2 = "", ""
		end
		t[#t+1] = "label[1.5,"..ypos..";\027(c@#000000)"..s1.."]"
		t[#t+1] = "label[5.5,"..ypos..";\027(c@#000000)"..s2.."]"
	end
	return table.concat(t, "")
end


local function button(label, on, x, y)
	local img
	if on then
		img = "pdp13_switch_form2.png"
	else
		img = "pdp13_switch_form1.png"
	end
	return "container["..x..","..y.."]"..
		"label[0,0.3;0]"..
		"image_button[0.3,0;1.2,1.2;"..img..";;]"..
		"label[1.4,0.3;1    "..label.."]"..
		"container_end[]"
end

local function formspec(number)
	local data = get_data(number)
	data.punch = not data.punch
	data.reader = not data.reader
	local txt = format_text(data.lines)
	return "size[12,9.5]" ..
--		"tablecolumns[text,width=12;text,width=12]" ..
--		"tableoptions[color=#000000]"..
		"background[1,0;10,7.2;pdp13_paper_form.png]"..
		txt..
		"list[context;main;0.5,8;1,1;]"..
		"image[0.5,8;1,1;pdp13_punched_tape.png]"..
		"field[2,9;7,1;cmnd;;]"..
		"field_close_on_enter[cmnd;false]"..
		button("punch", data.punch, 8.8, 7.4)..
		button("reader", data.reader, 8.8, 8.6)
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
		M(pos):set_string("formspec", formspec(own_num))
	end,
	on_rightclick = function(pos, node, clicker)
		local number = M(pos):get_string("node_number")
		M(pos):set_string("formspec", formspec(number))
	end,
	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		print(dump(fields))
		local number = M(pos):get_string("node_number")
		local data = get_data(number)
		local codes = {}
		if fields.pan == "PAN" or fields.key_enter == "true" then
			for _,s in ipairs(string.split(fields.cmnd, " ")) do
				s = s or ""
				s = string.match(s:trim(), "^([0-9a-fA-F]+)$") or ""
				local val = tonumber(s, 16)
				if val then
					data.codes[#data.codes+1] = val
					codes[#codes+1] = val
				end
			end
			local n,tbl = pdp13.disassemble(0, codes)
			for _,s in ipairs(tbl) do
				data.lines[#data.lines+1] = s
			end
		end
		M(pos):set_string("formspec", formspec(number))
	end,
	after_dig_node = function(pos, oldnode)
		--techage.power.after_dig_node(pos, oldnode)
		tubelib2.del_mem(pos)
	end,
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

--local function code_loader(pos, offs)
--	local mem = tubelib2.get_mem(pos)
--	if offs == 0 and mem.sent < mem.prog_size then
--		return 1
--	else
--		return 0
--	elseif offs == 1 then
--		local words = get_tbl(pos, "code")
--		local res = words[mem.sent]
--		mem.sent = mem.sent + 1
--		if idx >= size: 
		
--	end


--techage.register_node({"pdp13:telewriter"}, {
--	on_recv_message = function(pos, src, topic, payload)
--		if topic == "pdp13_info" then
--			return {
--				type = "I/O",
--				help = "IN: 0=state (0/1), 1=data; OUT: ?",
--			}
--		elseif topic == "pdp13_input" then -- from the pdp13 point of view
--			return {
--				credit = 10,
--				func = ,
--			}
--		end
--	end,
--})	

