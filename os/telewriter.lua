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
		return #s
	end
	return 65535
end

local function telewriter_input_number(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	return tonumber(s) or 65535
end

local function telewriter_read_tape(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "read_tape")
	if s then
		number = M(pos):get_string("node_number")
		number = tonumber(number)
		pdp13.SharedMemory[number] = s
	end
	return s and 1 or 0
end

local function telewriter_write_tape(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = pdp13.SharedMemory[number]
	pdp13.SharedMemory[number] = nil
	if s and vm16.is_ascii(s) then
		number = M(pos):get_string("telewriter_number")
		return send_cmnd(pos, number, "write_tape", s)
	end
	return 0
end


pdp13.SysDesc = [[
+-----+----------------+-------------+------+
|sys #| Telewriter     | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $0    string output    @text   -     1=ok 
 $1    string input     @dest   -     size
 $2    number input      -      -     number
 $3    read tape (>SM)   -      -     1=ok
 $4    write tape (<SM)  -      -     1=ok]]

pdp13.SysDesc = pdp13.SysDesc:gsub(",", "\\,")
pdp13.SysDesc = pdp13.SysDesc:gsub("\n", ",")
pdp13.SysDesc = pdp13.SysDesc:gsub("#", "\\#")
pdp13.SysDesc = pdp13.SysDesc:gsub(";", "\\;")


pdp13.register_SystemHandler(0, telewriter_print_string_ln)
pdp13.register_SystemHandler(1, telewriter_input_string)
pdp13.register_SystemHandler(2, telewriter_input_number)
pdp13.register_SystemHandler(3, telewriter_read_tape)
pdp13.register_SystemHandler(4, telewriter_write_tape)

