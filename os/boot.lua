--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Boot process

]]--
-- for lazy programmers
local M = minetest.get_meta

local function read_boot_file(pos, fname)
	print("read_boot_file")
	local s
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, fname, 0, 0x0000)
	if fref then
		local res = pdp13.sys_call(pos, pdp13.READ_LINE, fref, 0)
		if res > 0 then
			s = vm16.read_ascii(pos, 0x0000, pdp13.MAX_LINE_LEN)
		end
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
	end
	if s and pdp13.is_h16_file(s) then
		return s
	end
end

local function load_h16file(pos, address, val1, val2)
	print("load_h16file")
	local res = 0
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, 0)
	if fref then
		if pdp13.sys_call(pos, pdp13.READ_FILE, fref, 0) == 1 then
			local number = M(pos):get_string("node_number")
			number = tonumber(number)
			local s = pdp13.SharedMemory[number]
			if s and type(s) == "string" and s ~= "" then
				vm16.write_h16(pos, s)
				res = 1
			end
		end
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
	end
	return res
end

local function warm_start(pos, address, val1, val2)
	print("warm_start")
	local regs = vm16.get_cpu_reg(pos)
	regs.A = 0
	regs.B = 0
	regs.C = 0
	regs.D = 0
	regs.X = 0
	regs.Y = 0
	regs.PC = 0
	regs.SP = 0
	vm16.set_cpu_reg(pos, regs)
	return 1
end

local function cold_start(pos, address, val1, val2)
	print("cold_start")
	
	local fname = read_boot_file(pos, "t/boot") or read_boot_file(pos, "h/boot")
	if fname then
		if pdp13.sys_call(pos, pdp13.LOAD_H16, fname, val2, 0x0000) == 1 then
			local mem = techage.get_mem(pos)
			local drive, _ = pdp13.filename(fname, mem.current_drive)
			pdp13.set_current_drive(mem, drive)
			warm_start(pos, address, val1, val2)
			return 1
		end
	end
	return 0
end
	
local function get_rom_size(pos, address, val1, val2)
	print("get_rom_size")
	local rom_size = M(pos):get_int("rom_size")
	
	return pdp13.tROM_SIZE[rom_size]
end

local function get_current_drive(pos, address, val1, val2)
	print("get_current_drive")
	local mem = techage.get_mem(pos)
	return string.byte(mem.current_drive or 't', 1)
end


local help = [[+-----+----------------+-------------+------+
|sys #| Boot           | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $70   cold start        -      -     NO RET
 $71   warm start        -      -     NO RET
 $72   load h16file     @fname  -     1=ok
 $73   ROM size          -      -     size K
 $74   current drive     -      -     drive]]

pdp13.register_SystemHandler(0x70, cold_start, help)
pdp13.register_SystemHandler(0x71, warm_start)
pdp13.register_SystemHandler(0x72, load_h16file)
pdp13.register_SystemHandler(0x73, get_rom_size)
pdp13.register_SystemHandler(0x74, get_current_drive)

