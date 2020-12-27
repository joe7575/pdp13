--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Telewriter SYS commands

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local NUM_CHARS = pdp13.MAX_LINE_LEN

local function send_cmnd(pos, dst_num, topic, payload)
	local own_num = M(pos):get_string("node_number")
	return techage.send_single(own_num, dst_num, topic, payload)
end

local function telewriter_print_string_ln(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = vm16.read_ascii(pos, val1, NUM_CHARS)
	return send_cmnd(pos, number, "println", s)
end

local function telewriter_input_string(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	if s and vm16.write_ascii(pos, val1, s.."\000") then
		--print("telewriter_input_string", val1, s)
		return #s
	end
	return 65535
end

local function telewriter_input_number(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	--print("telewriter_input_number", s, tonumber(s) or 65535)
	return tonumber(s) or 65535
end

local function telewriter_print_char(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	if val1 > 255 then
		local s = string.char(pdp13.range(val1 / 256, 32, 127, 46))..
		          string.char(pdp13.range(val1 % 256, 32, 127, 46))
		return send_cmnd(pos, number, "print", s)
	else
		local s = string.char(pdp13.range(val1, 32, 127, 46))
		return send_cmnd(pos, number, "print", s)
	end
end

local function telewriter_print_number(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s
	if val2 == 16 then
		s = string.format("%04X", val1)
	else
		s = tostring(val1)
	end
	return send_cmnd(pos, number, "print", s)
end

local function telewriter_print_string(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = vm16.read_ascii(pos, val1, NUM_CHARS)
	return send_cmnd(pos, number, "print", s)
end


pdp13.SysDesc = [[
+-----+----------------+-------------+------+
|sys #| Telewriter     | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $0    println string   @text   -     1=ok 
 $1    string input     @dest   -     size
 $2    number input      -      -     number
 $3    print char       char    -     1=ok
 $4    print number     number  base  1=ok
 $5    print string     @text   -     1=ok]]

pdp13.SysDesc = pdp13.SysDesc:gsub(",", "\\,")
pdp13.SysDesc = pdp13.SysDesc:gsub("\n", ",")
pdp13.SysDesc = pdp13.SysDesc:gsub("#", "\\#")
pdp13.SysDesc = pdp13.SysDesc:gsub(";", "\\;")


pdp13.register_SystemHandler(0, telewriter_print_string_ln)
pdp13.register_SystemHandler(1, telewriter_input_string)
pdp13.register_SystemHandler(2, telewriter_input_number)
pdp13.register_SystemHandler(3, telewriter_print_char)
pdp13.register_SystemHandler(4, telewriter_print_number)
pdp13.register_SystemHandler(5, telewriter_print_string)

