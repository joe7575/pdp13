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
	return pdp13.send_single(own_num, dst_num, topic, payload)
end

local function telewriter_print_string_ln(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = vm16.read_ascii(pos, val1, NUM_CHARS)
	return send_cmnd(pos, number, "println", s)
end

local function telewriter_input_string(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	if s and vm16.write_ascii(pos, val1, s) then
		return string.len(s)
	end
	return 0
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
		local items = pdp13.text2table(s)
		return pdp13.push_pipe(pos, items)
	end
	return 0
end

local function telewriter_write_tape(pos, address, val1, val2)
	local items = pdp13.pop_pipe(pos, pdp13.MAX_PIPE_LEN)
	local s = table.concat(items, "\n")
	if s and vm16.is_ascii(s) then
		local number = M(pos):get_string("telewriter_number")
		return send_cmnd(pos, number, "write_tape", s)
	end
	return 0
end

local function telewriter_read_tape_name(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "tape_name")
	if s ~= "" and vm16.write_ascii(pos, val1, s) then
		pdp13.tape_detected(pos, s)
		return string.len(s)
	end
	return 0
end

local function telewriter_tape_sound(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	return send_cmnd(pos, number, "tape_sound") or 0
end


local help = [[
+-----+----------------+-------------+------+
|sys #| Telewriter     | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $0    string output    @text   -     1=ok 
 $1    string input     @dest   -     size
 $2    number input      -      -     number
 $3    read tape (>p)    -      -     lines
 $4    write tape (<p)   -      -     1=ok
 $5    read tape name   @dest   -     1=ok
 $6    tape sound        -      -     1=ok]]

pdp13.register_SystemHandler(0, telewriter_print_string_ln, help)
pdp13.register_SystemHandler(1, telewriter_input_string)
pdp13.register_SystemHandler(2, telewriter_input_number)
pdp13.register_SystemHandler(3, telewriter_read_tape)
pdp13.register_SystemHandler(4, telewriter_write_tape)
pdp13.register_SystemHandler(5, telewriter_read_tape_name)
pdp13.register_SystemHandler(6, telewriter_tape_sound)

