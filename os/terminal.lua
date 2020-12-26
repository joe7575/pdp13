--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Terminal SYS commands

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local NUM_CHARS = pdp13.MAX_LINE_LEN
local SCREENBUFFER_SIZE = 48*16

local function send_terminal_command(cpu_pos, cmnd, payload)
	local mem = techage.get_nvm(cpu_pos)
	mem.term_pos = mem.term_pos or S2P(M(cpu_pos):get_string("terminal_pos"))
	return pdp13.send(cpu_pos, mem.term_pos, nil, cmnd, payload)
end

local function sys_clear_screen(cpu_pos)
	print("clear_screen")
	return send_terminal_command(cpu_pos, "clear")
end

local function sys_print_char(cpu_pos, address, val1)
	print("print_char")
	if val1 > 255 then
		local s = string.char(pdp13.range(val1 / 256, 32, 127, 46))..
		          string.char(pdp13.range(val1 % 256, 32, 127, 46))
		return send_terminal_command(cpu_pos, "print", s)
	else
		local s = string.char(pdp13.range(val1, 32, 127, 46))
		return send_terminal_command(cpu_pos, "print", s)
	end
end

local function sys_print_number(cpu_pos, address, val1, val2)
	print("print_number")
	local s
	
	if val2 == 16 then
		s = string.format("%04X", val1)
	else
		s = tostring(val1)
	end
	return send_terminal_command(cpu_pos, "print", s)
end

local function sys_print_string(cpu_pos, address, val1)
	print("print_string")
	local s = vm16.read_ascii(cpu_pos, val1, NUM_CHARS)
	return send_terminal_command(cpu_pos, "print", s)
end

local function sys_print_string_ln(cpu_pos, address, val1)
	print("print_string_ln")
	local s = vm16.read_ascii(cpu_pos, val1, NUM_CHARS)
	return send_terminal_command(cpu_pos, "println", s)
end

local function sys_update_screen(cpu_pos, address, val1)
	print("update_screen")
	local s = vm16.read_ascii(cpu_pos, val1, SCREENBUFFER_SIZE)
	return send_terminal_command(cpu_pos, "update", s)
end

local function sys_editor_start(cpu_pos, address, val1)
	print("edit_start")
	local number = M(cpu_pos):get_string("node_number")
	number = tonumber(number)
	local text = pdp13.SharedMemory[number] or ""
	return send_terminal_command(cpu_pos, "edit", text)
end

local function sys_input_string(cpu_pos, address, val1)
	print("input_string")
	local s = send_terminal_command(cpu_pos, "input")
	if s and vm16.write_ascii(cpu_pos, val1, s.."\000") then
		return #s
	end
	return 65535
end

local function sys_print_shared_mem(cpu_pos, address, val1)
	local number = M(cpu_pos):get_string("node_number")
	number = tonumber(number)
	local sm = pdp13.SharedMemory[number]
	print("print_shared mem", dump(sm))
	if type(sm) == "string" then
		for s in sm:gmatch("[^\n]+") do
			send_terminal_command(cpu_pos, "println", s)
		end
		return 1
	elseif type(sm) == "table" then
		for _,s in ipairs(sm) do
			send_terminal_command(cpu_pos, "println", s)
		end
		return 1
	end
	return 0
end


local help = [[+-----+-----------------+------------+------+
|sys #| Terminal       | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $10   clear screen      -      -     1=ok
 $11   print char       char    -     1=ok
 $12   print number     number  base  1=ok
 $13   print string     @text   -     1=ok
 $14   println string   @text   -     1=ok
 $15   update screen    @text   -     1=ok
 $16   start editor      -      -     1=ok
 $17   input string     @dest   -     size
 $18   print SM (<SM)   -       -     1=ok]]

pdp13.register_SystemHandler(0x10, sys_clear_screen, help)
pdp13.register_SystemHandler(0x11, sys_print_char)
pdp13.register_SystemHandler(0x12, sys_print_number)
pdp13.register_SystemHandler(0x13, sys_print_string)
pdp13.register_SystemHandler(0x14, sys_print_string_ln)
pdp13.register_SystemHandler(0x15, sys_update_screen)
pdp13.register_SystemHandler(0x16, sys_editor_start)
pdp13.register_SystemHandler(0x17, sys_input_string)
pdp13.register_SystemHandler(0x18, sys_print_shared_mem)