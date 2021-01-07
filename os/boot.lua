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

-- fname in val1/addr1
-- dest addr in val2
local function read_first_file_line(pos, val1, val2, addr1)
	local s
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, 0, addr1)
	if fref then
		local res = pdp13.sys_call(pos, pdp13.READ_LINE, fref, val2)
		if res > 0 then
			s = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)
		end
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
	end
	return s
end

local function load_h16file(pos, address, val1, val2)
	local res = 0
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, 0)
	if fref then
		local s = pdp13.read_file(pos, fref)
		if s then
			vm16.write_h16(pos, s)
			res = 1
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
	regs.PC = pdp13.WARMSTART_ADDR
	regs.SP = 0
	vm16.set_cpu_reg(pos, regs)
	return 1
end

local function cold_start(pos, address, val1, val2)
	print("cold_start")
	pdp13.sys_call(pos, 2, 0x0000, 0)  -- Flush Telewriter input
	pdp13.sys_call(pos, pdp13.INPUT, 0x0000, 0)  -- Flush Terminal input
	
	local addr_fname = 0x0000
	local addr_dest  = 0x0040
	local fname = read_first_file_line(pos, "t/boot", addr_dest, addr_fname) or 
			read_first_file_line(pos, "h/boot", addr_dest, addr_fname)
	if fname and pdp13.is_h16_file(fname) then
		if pdp13.sys_call(pos, pdp13.LOAD_H16, addr_dest, 0) == 1 then
			local mem = techage.get_mem(pos)
			local drive, _ = pdp13.filename(fname, mem.current_drive)
			mem.current_drive = drive
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
	end
	return 0
end

-- API function to get as much info about boot issues as possible
function pdp13.cold_start(pos)
	local addr_fname = 0x0000
	local addr_dest  = 0x0040
	
	-- boot file
	local sts = pdp13.file_exists(pos, "t/boot") or pdp13.file_exists(pos, "h/boot")
	if not sts then return 2 end -- boot file missing
	
	-- shell1.h16 file
	local fname = read_first_file_line(pos, "t/boot", addr_dest, addr_fname) or 
			read_first_file_line(pos, "h/boot", addr_dest, addr_fname)
	sts = pdp13.file_exists(pos, fname)
	if not sts then return 3 end -- shell1.h16 (or corresponding file) file missing
	
	-- test .h16 file (shell1.h16)
	sts = fname and pdp13.is_h16_file(fname)
	if not sts then return 4 end -- shell1.h16 (or corresponding .h16 file) file corrupt
	
	return cold_start(pos)
end
	
local function get_rom_size(pos, address, val1, val2)
	local rom_size = M(pos):get_int("rom_size")
	
	return pdp13.tROM_SIZE[rom_size]
end

local function get_ram_size(pos, address, val1, val2)
	local ram_size = M(pos):get_int("ram_size")
	
	return ram_size
end

local function get_current_drive(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	return string.byte(mem.current_drive or 't', 1)
end

local function load_comfile(pos, address, val1, val2)
	local res = 0
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, 0)
	if fref then
		local s = pdp13.read_file(pos, fref)
		if s then
			vm16.write_mem_bin(pos, pdp13.START_ADDR, s)
			res = 1
		end
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
	end
	return res
end

local function h16_size(pos, address, val1, val2)
	local s = read_first_file_line(pos, val1, val2)
	
	if s and s ~= "" then
		--   :20000010000000D
		local rowtype = tonumber(s:sub(7,8))
		local addrmin = tonumber(s:sub(9,12), 16)
		local addrmax = tonumber(s:sub(13,16), 16)
		
		if rowtype == 1 and addrmin and addrmax then
			return addrmax - addrmin + 1
		end
	end
	return 0
end

local function com_size(pos, address, val1, val2)
	return pdp13.sys_call(pos, pdp13.FILE_SIZE, val1, val2)
end

-- Fileame via A Reg
-- Size via B Reg
local function store_as_com(pos, address, val1, val2)
	local s = vm16.read_mem_bin(pos, pdp13.START_ADDR, val2)
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, pdp13.WR)
	if s and fref then
		pdp13.write_file(pos, fref, s)
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
		return 1
	end
	return 0
end

-- Fileame via A Reg
local function store_as_h16(pos, address, val1, val2)
	local s = vm16.read_h16(pos. pdp13.START_ADDR, val2)
	local fref = pdp13.sys_call(pos, pdp13.FOPEN, val1, pdp13.WR)
	if s and fref then
		pdp13.write_file(pos, fref, s)
		pdp13.sys_call(pos, pdp13.FCLOSE, fref, 0)
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Boot           | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $70   cold start        -      -     NO RET
 $71   warm start        -      -     NO RET
 $72   ROM size          -      -     size K
 $73   RAM size          -      -     size K
 $74   current drive     -      -     drive
 $75   load .h16 file   @fname  -     1=ok
 $76   load .com file   @fname  -     1=ok
 $77   size .h16 file   @fname  -     size
 $78   size .com file   @fname  -     size
 $79   store .h16 file  @fname  size  1=ok
 $7A   store .com file  @fname  size  1=ok]]
 
pdp13.register_SystemHandler(0x70, cold_start, help)
pdp13.register_SystemHandler(0x71, warm_start)
pdp13.register_SystemHandler(0x72, get_rom_size)
pdp13.register_SystemHandler(0x73, get_ram_size)
pdp13.register_SystemHandler(0x74, get_current_drive)
pdp13.register_SystemHandler(0x75, load_h16file)
pdp13.register_SystemHandler(0x76, load_comfile)
pdp13.register_SystemHandler(0x77, h16_size)
pdp13.register_SystemHandler(0x78, com_size)
pdp13.register_SystemHandler(0x79, store_as_h16)
pdp13.register_SystemHandler(0x7A, store_as_com)

