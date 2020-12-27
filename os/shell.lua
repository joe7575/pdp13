--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Shell extension

]]--

-- for lazy programmers
local M = minetest.get_meta

local OS_ENA	= 2  -- OS enables
local FS_ENA	= 3  -- File System enabled
local PROMPT    = "[pdp13] t/$ "

local Commands = {}  -- [cmnd] = func(pos, mem, cmd, rest): returns list of output strings
local Files = pdp13.Files

local function is_filename(s)
	return string.find(s, "^%a%w+%.asm$") or string.find(s, "^%a%w+%.h16$")
end

Commands["help"] = function(pos, mem, cmd, rest)
	return "help", {
		PROMPT..cmd..rest,
		"ed        edit",
		"asm       compile",
		"run       execute",
	}
end

-- edit
Commands["ed"] = function(pos, mem, cmd, rest)
	local rom_size = M(pos):get_int("rom_size")
	if rom_size >= OS_ENA then
		local filename = "main.asm"
		if rom_size >= FS_ENA and is_filename(rest) then
			filename = rest
		end
		local number = M(pos):get_string("node_number")
		number = tonumber(number)
		Files[number] = Files[number] or {}
		local text = Files[number][filename] or ""
		return "edit", text
	end
	return "error", {"error"}
end

-- assembler
Commands["asm"] = function(pos, mem, cmd, rest)
	return "error", {PROMPT..cmd..rest, "error"}
end

-- run
Commands["run"] = function(pos, mem, cmd, rest)
	return "error", {PROMPT..cmd..rest, "error"}
end

function pdp13.shell(cpu_pos, mem, command)
	if cpu_pos and mem and command then
		local words = string.split(command, " ", false, 1)
		print("shell", words[1], words[2])
		if Commands[words[1]] then
			return Commands[words[1]](cpu_pos, mem, words[1] or "", words[2] or "")
		else
			return Commands["help"](cpu_pos, mem, words[1] or "", words[2] or "")
		end
	end
	return "error", {PROMPT..command, "error"}
end

function pdp13.shell_file_save(pos, mem, text)
	local rom_size = M(pos):get_int("rom_size")
	if rom_size >= OS_ENA then
		local number = M(pos):get_string("node_number")
		number = tonumber(number)
		mem.filename = mem.filename or "main.asm"
		Files[number] = Files[number] or {}
		Files[number][mem.filename] = text
		return {PROMPT..cmd..rest, "File stored"}
	end
	return {PROMPT..cmd..rest, "error"}
end	