--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 CPU

]]--

local MP = minetest.get_modpath("pdp13")

pdp13 = {}

-- Data maintenance
dofile(MP.."/lib/lib.lua")
dofile(MP.."/lib/scheduler.lua")
dofile(MP.."/lib/owner.lua")
dofile(MP.."/lib/states.lua")
dofile(MP.."/lib/disasm.lua")

-- PDP-13
dofile(MP.."/pdp13/cpu.lua")
dofile(MP.."/pdp13/power.lua")
dofile(MP.."/pdp13/rom4k.lua")
dofile(MP.."/pdp13/ram.lua")
dofile(MP.."/pdp13/chassis.lua")

-- I/O
dofile(MP.."/io/7segment.lua")
dofile(MP.."/io/telewriter.lua")
dofile(MP.."/io/tape.lua")

