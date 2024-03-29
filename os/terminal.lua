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
local NUM_LINES = 16
local SCREENBUFFER_SIZE = NUM_CHARS * NUM_LINES

local function send_terminal_command(cpu_pos, mem, cmnd, payload)
	if M(cpu_pos):get_int("rom_size") >= 2 then  -- BIOS enabled
		mem.term_pos = mem.term_pos or S2P(M(cpu_pos):get_string("terminal_pos"))
		return pdp13.send(cpu_pos, mem.term_pos, nil, cmnd, payload)
	end
	return 0
end

pdp13.send_terminal_command = send_terminal_command

local function sys_clear_screen(cpu_pos)
	local mem = pdp13.get_nvm(cpu_pos)
	
	mem.stdout = ""
	send_terminal_command(cpu_pos, mem, "clear")
	return 1
end

local function sys_print_char(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	
	if val1 > 255 then
		mem.stdout = mem.stdout..
				string.char(pdp13.range(val1 / 256, 32, 127, 46))..
		        string.char(pdp13.range(val1 % 256, 32, 127, 46))
	else
		mem.stdout = mem.stdout..
				string.char(pdp13.range(val1, 32, 127, 46))
	end
	return 1, 100
end

local function sys_print_number(cpu_pos, address, val1, val2)
	local mem = pdp13.get_nvm(cpu_pos)
	
	if val2 == 16 then
		mem.stdout = mem.stdout..string.format("%04X", val1)
	else
		mem.stdout = mem.stdout..tostring(val1)
	end
	return 1, 200
end

local function sys_print_string(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	
	local s = vm16.read_ascii(cpu_pos, val1, NUM_CHARS)
	mem.stdout = mem.stdout..s
	return 1, 200
end

local function sys_print_string_ln(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	
	local s = vm16.read_ascii(cpu_pos, val1, NUM_CHARS)
	mem.stdout = mem.stdout..s
	send_terminal_command(cpu_pos, mem, "println", mem.stdout)
	mem.stdout = ""
	return 1
end

local function sys_flush_stdout(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	send_terminal_command(cpu_pos, mem, "print", mem.stdout)
	mem.stdout = ""
end

local function sys_update_screen(cpu_pos, address, val1)
	local s = vm16.read_ascii(cpu_pos, val1, SCREENBUFFER_SIZE)
	local mem = pdp13.get_nvm(cpu_pos)
	send_terminal_command(cpu_pos, mem, "update", s)
	return 1
end

local function sys_editor_start(cpu_pos, address, val1)
	local fname = vm16.read_ascii(cpu_pos, val1, pdp13.MAX_FNAME_LEN)
	local items = pdp13.pop_pipe(cpu_pos, pdp13.MAX_PIPE_LEN)
	local mem = pdp13.get_nvm(cpu_pos)
	if not next(items) or vm16.is_ascii(items[1]) then
		local text = table.concat(items or {}, "\n")
		send_terminal_command(cpu_pos, mem, "edit", {text = text, fname = fname})
		return 1
	else
		send_terminal_command(cpu_pos, mem, "println", "format error")
		pdp13.sys_call(cpu_pos, pdp13.PROMPT, 0, 0)
		return 0
	end
end

local function sys_input_string(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	local s = send_terminal_command(cpu_pos, mem, "input")
	if s and vm16.write_ascii(cpu_pos, val1, s) then
		return #s
	end
	return 0
end

local function sys_print_pipe(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	local items = pdp13.pop_pipe(cpu_pos, val1)
	for _,s in ipairs(items) do
		if s == "" or vm16.is_ascii(s) then
			send_terminal_command(cpu_pos, mem, "println", s)
		else
			--print(dump(s))
			send_terminal_command(cpu_pos, mem, "println", "invalid data")
		end
	end
	return 1
end

local function sys_prompt(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	local cwd = pdp13.path.get_curr_wdir(mem)
	send_terminal_command(cpu_pos, mem, "print", cwd..">")
	mem.stdout = ""
	return 1
end

local function sys_beep(cpu_pos, address, val1)
	local mem = pdp13.get_nvm(cpu_pos)
	mem.term_pos = mem.term_pos or S2P(M(cpu_pos):get_string("terminal_pos"))
	minetest.sound_play("pdp13_beep", {
		pos = mem.term_pos, 
		gain = 1,
		max_hear_distance = 5})
	return 1
end

local help = [[+-----+----------------+-------------+------+
|sys #| Terminal       | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $10   clear screen      -      -     1=ok
 $11   print char       char    -     1=ok
 $12   print number     number  base  1=ok
 $13   print string     @text   -     1=ok
 $14   println string   @text   -     1=ok
 $15   update screen    @text   -     1=ok
 $16   start edit (<p)  @fname  -     1=ok
 $17   input string     @dest   -     size
 $18   print pipe       lines   -     1=ok
 $19   flush stdout     -       -     1=ok
 $1A   prompt           -       -     1=ok
 $1B   beep             -       -     1=ok]]

pdp13.register_SystemHandler(0x10, sys_clear_screen, help)
pdp13.register_SystemHandler(0x11, sys_print_char)
pdp13.register_SystemHandler(0x12, sys_print_number)
pdp13.register_SystemHandler(0x13, sys_print_string)
pdp13.register_SystemHandler(0x14, sys_print_string_ln)
pdp13.register_SystemHandler(0x15, sys_update_screen)
pdp13.register_SystemHandler(0x16, sys_editor_start)
pdp13.register_SystemHandler(0x17, sys_input_string)
pdp13.register_SystemHandler(0x18, sys_print_pipe)
pdp13.register_SystemHandler(0x19, sys_flush_stdout)
pdp13.register_SystemHandler(0x1A, sys_prompt)
pdp13.register_SystemHandler(0x1B, sys_beep)
