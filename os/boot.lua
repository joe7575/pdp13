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


local function h16_size(s)
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

local function load_comfile(pos, fname)
	local path = pdp13.get_exe_path(pos, fname)
	local s = pdp13.read_file(pos, path)
	if s and #s > 2 then
		local word = string.byte(s, 1) + string.byte(s, 2) * 256
		if word == pdp13.COMTAG_V1 then
			vm16.write_mem_bin(pos, pdp13.START_ADDR, s)
			return 1
		end
	end
	local mem = techage.get_nvm(pos)
	pdp13.send_terminal_command(pos, mem, "println", "Error: Invalid .com file!")
	return 0
end

local function load_h16file(pos, fname)
	local path = pdp13.get_exe_path(pos, fname)
	local s = pdp13.read_file(pos, path)
	if s then
		vm16.write_h16(pos, s)
		return 1
	end
	local mem = techage.get_nvm(pos)
	pdp13.send_terminal_command(pos, mem, "println", "Error: Invalid .h16 file!")
	return 0
end

local function load_batfile(pos, fname)
	local path = pdp13.get_exe_path(pos, fname)
	local s = pdp13.read_file(pos, path)
	if s then
		local items = pdp13.text2table(s)
		pdp13.push_pipe(pos, items)
		return 1
	end
	local mem = techage.get_nvm(pos)
	pdp13.send_terminal_command(pos, mem, "println", "Error: Invalid .bat file!")
	return 0
end

local function file_exists(pos, fname)
	local path = pdp13.get_exe_path(pos, fname)
	return pdp13.file_exists(pos, path) and 1 or 0
end

local function sys_warm_start(pos, address, val1, val2)
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

function pdp13.cold_start(pos)
	print("cold_start")
	pdp13.sys_call(pos, 2, 0x0000, 0)  -- Flush Telewriter input
	pdp13.sys_call(pos, pdp13.INPUT, 0x0000, 0)  -- Flush Terminal input
	
	-- boot file
	local sts = pdp13.file_exists(pos, "t/boot") or 
			pdp13.file_exists(pos, "h/boot") or pdp13.file_exists(pos, "h/bin/boot")
	if not sts then return 2 end -- file 'boot' is missing
	
	local fname = pdp13.read_file(pos, "t/boot") or 
			pdp13.read_file(pos, "h/boot") or pdp13.read_file(pos, "h/bin/boot")
	if not fname then return 3 end  -- file 'boot' is invalid
	if not pdp13.path.has_ext(fname, "h16") then return 4 end  -- file 'boot' is invalid
	if not pdp13.file_exists(pos, fname) then return 5 end  -- file 'shell1.h16' is missing
	local s = pdp13.read_file(pos, fname)
	if not s or not vm16.is_ascii(s) then return 6 end  -- file 'shell1.h16' is no ASCII file
	if h16_size(s) == 0 then return 7 end  -- file 'shell1.h16' is no valid h16 file
	
	vm16.write_h16(pos, s)
	
	local mem = techage.get_nvm(pos)
	local drive, _, _ = pdp13.path.splitpath(mem, fname)
	pdp13.change_drive(pos, drive)
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

local function sys_get_rom_size(pos, address, val1, val2)
	local rom_size = M(pos):get_int("rom_size")
	
	return pdp13.tROM_SIZE[rom_size]
end

local function sys_get_ram_size(pos, address, val1, val2)
	local ram_size = M(pos):get_int("ram_size")
	
	return ram_size
end

local function sys_load_comfile(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	if path then
		return load_comfile(pos, path)
	end
end

local function sys_load_h16file(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	if path then
		return load_h16file(pos, path)
	end
end

local function sys_load_batfile(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	if path then
		return load_batfile(pos, path)
	end
end

local function sys_h16_size(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	local path = pdp13.get_exe_path(pos, fname)
	local s = pdp13.read_file(pos, path)
	return h16_size(s)
end

local function sys_com_size(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	local path = pdp13.get_exe_path(pos, fname)
	return pdp13.file_size(pos, path)
end

-- Fileame via A Reg
-- Size via B Reg
local function sys_store_as_com(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	local path = pdp13.get_exe_path(pos, fname)
	local s = vm16.read_mem_bin(pos, pdp13.START_ADDR, val2)
	if path and s then
		return pdp13.write_file(pos, path, s) and 1 or 0
	end
	return 0
end

-- Fileame via A Reg
-- Size via B Reg
local function sys_store_as_h16(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	local path = pdp13.get_exe_path(pos, fname)
	local s = vm16.read_h16(pos. pdp13.START_ADDR, val2)
	if path and s then
		return pdp13.write_file(pos, path, s) and 1 or 0
	end
	return 0
end


local function sys_file_exists(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.path.MAX_PATH_LEN)
	return file_exists(pos, fname)
end

local help = [[+-----+----------------+-------------+------+
|sys #| Boot           | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $70   cold start        -      -     NO RET
 $71   warm start        -      -     NO RET
 $72   ROM size          -      -     size K
 $73   RAM size          -      -     size K
 $75   load .h16 file   @fname  -     1=ok
 $76   load .com file   @fname  -     1=ok
 $77   size .h16 file   @fname  -     size
 $78   size .com file   @fname  -     size
 $79   store .h16 file  @fname  size  1=ok
 $7A   store .com file  @fname  size  1=ok
 $7B   load .bat (>p)   @fname  -     1=ok
 $7C   file exists      @fname  -     1=ok]]
 
pdp13.register_SystemHandler(0x70, pdp13.cold_start, help)
pdp13.register_SystemHandler(0x71, sys_warm_start)
pdp13.register_SystemHandler(0x72, sys_get_rom_size)
pdp13.register_SystemHandler(0x73, sys_get_ram_size)
pdp13.register_SystemHandler(0x75, sys_load_h16file)
pdp13.register_SystemHandler(0x76, sys_load_comfile)
pdp13.register_SystemHandler(0x77, sys_h16_size)
pdp13.register_SystemHandler(0x78, sys_com_size)
pdp13.register_SystemHandler(0x79, sys_store_as_h16)
pdp13.register_SystemHandler(0x7A, sys_store_as_com)
pdp13.register_SystemHandler(0x7B, sys_load_batfile)
pdp13.register_SystemHandler(0x7C, sys_file_exists)

vm16.register_sys_cycles(0x70, 10000)
vm16.register_sys_cycles(0x71, 10000)
vm16.register_sys_cycles(0x75, 10000)
vm16.register_sys_cycles(0x76, 10000)
vm16.register_sys_cycles(0x79, 10000)
vm16.register_sys_cycles(0x7A, 10000)
vm16.register_sys_cycles(0x7B, 10000)


pdp13.boot = {}
pdp13.boot.file_exists = file_exists
pdp13.boot.load_comfile = load_comfile
pdp13.boot.load_h16file = load_h16file

