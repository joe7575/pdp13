--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 CPU

]]--

local MP = minetest.get_modpath("pdp13")

pdp13 = {}

dofile(MP.."/lib/io_lib.lua")
dofile(MP.."/lib/command.lua")
dofile(MP.."/lib/opcodes.lua")
dofile(MP.."/lib/assemble.lua")
dofile(MP.."/lib/disasm.lua")
--dofile(MP.."/lib/editor.lua")

-- PDP-13
dofile(MP.."/pdp13/system.lua")
dofile(MP.."/pdp13/cpu.lua")
dofile(MP.."/pdp13/power.lua")
dofile(MP.."/pdp13/io_rack.lua")

-- I/O
dofile(MP.."/io/lamp.lua")
dofile(MP.."/io/7segment.lua")
dofile(MP.."/io/telewriter.lua")
--dofile(MP.."/io/tape.lua")
