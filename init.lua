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

-- Library
dofile(MP.."/lib/storage.lua")
dofile(MP.."/lib/io_lib.lua")
dofile(MP.."/lib/command.lua")
dofile(MP.."/lib/system.lua")

-- OS
dofile(MP.."/os/asm_help.lua")
dofile(MP.."/os/opcodes.lua")
dofile(MP.."/os/assemble.lua")
dofile(MP.."/os/disassemble.lua")
dofile(MP.."/os/monitor.lua")
dofile(MP.."/os/telewriter.lua")
dofile(MP.."/os/terminal.lua")
dofile(MP.."/os/std_lib.lua")
dofile(MP.."/os/comm.lua")
dofile(MP.."/os/filesystem.lua")
--dofile(MP.."/os/shell.lua")


-- PDP-13
dofile(MP.."/pdp13/cpu.lua")
dofile(MP.."/pdp13/power.lua")
dofile(MP.."/pdp13/io_rack.lua")
dofile(MP.."/pdp13/mem_rack.lua")
dofile(MP.."/pdp13/tape_drive.lua")

-- I/O
dofile(MP.."/io/lamp.lua")
dofile(MP.."/io/7segment.lua")
dofile(MP.."/io/telewriter.lua")
dofile(MP.."/io/terminal.lua")

-- Items
dofile(MP.."/items/tape.lua")
dofile(MP.."/items/demotape.lua")
dofile(MP.."/items/chips.lua")

-- Exams
dofile(MP.."/exam/exam1.lua")
dofile(MP.."/exam/exam2.lua")

-- Manuals
dofile(MP.."/manuals/manual_DE.lua")
dofile(MP.."/manuals/manual_EN.lua")

techage.add_manual_items({
		pdp13_cpu = "pdp13:cpu1",
		pdp13_iorack = "pdp13:io_rack",
		pdp13_telewriter = "pdp13:telewriter",
		pdp13_tape = "pdp13:tape",
		pdp13_7segment = "pdp13:7segment10",
		pdp13_lamp = "pdp13:lamp_off",
})
