--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 File System for tape drive and hard disk

]]--

-- for lazy programmers
local M = minetest.get_meta

local OS_ENA	= 2  -- OS enables
local FS_ENA	= 3  -- File System enabled
local FILE_NAME_LEN = 12
local LINE_LEN = 64

local Files = pdp13.Files
local SharedMemory = {} -- used for large text chunks or tables of strings
local OpenFiles = {}
local OpenFilesRef = 1

pdp13.SharedMemory = SharedMemory

local function range(val, min, max, default)
	val = tonumber(val) or default
	val = math.max(val, min)
	val = math.min(val, max)
	return val
end

local function gen_pattern(s)
	s = string.gsub(s, "%.", "%%.")
	s = string.gsub(s, "*", "%.%.%-")
	return "^"..s.."$"
end

local function fmatch(s, pattern)
	return string.find(s, pattern) ~= nil
end

-- "h/myfile" or "t/myfile"
local function filename(s)
	if string.find(s, "^([ht])/([%w_][%w_][%w_%.]+)$") then
		local drive = (s:byte(1) == 104 and 1) or (s:byte(1) == 116 and 2) or nil
		local fname = s:sub(3)
		return drive, fname
	end
end

-- "h/myfile" or "t/myfile"
local function filespattern(s)
	if string.find(s, "^([ht])/([%w_%.%*]+)$") then
		local drive = (s:byte(1) == 104 and 1) or (s:byte(1) == 116 and 2) or nil
		local fname = s:sub(3)
		return drive, fname
	end
end

local function max_num_files(drive)
	if drive == 1 then
		return 64
	else
		return 8
	end
end
	
local function max_fs_size(drive)
	if drive == 1 then
		return 200  -- kByte
	else
		return 25  -- kByte
	end
end

local function kbyte(val)
	if val > 0 then
		return math.floor(val / 1024) + 1
	end
	return 0
end

local function fopen(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive, fname = filename(s)
	if drive then
		Files[number] = Files[number] or {}
		Files[number][drive] = Files[number][drive] or {}
		Files[number][drive][fname] = Files[number][drive][fname] or ""
		if not OpenFiles[OpenFilesRef] then
			OpenFiles[OpenFilesRef] = {fpos = 1, number = number, drive = drive, fname = fname}
			OpenFilesRef = OpenFilesRef + 1
			return OpenFilesRef - 1
		end
	end
	return 0
end

local function fclose(pos, address, val1)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	if OpenFiles[val1] then
		OpenFiles[val1] = nil
		return 1
	end
	return 0
end

local function read_file(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	if OpenFiles[val1] then
		local number = OpenFiles[val1].number
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		SharedMemory[number] = Files[number][drive][fname]
		return 1
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	SharedMemory[number] = nil
	return 0
end

local function read_line(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	if OpenFiles[val1] then
		local number = OpenFiles[val1].number
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		local first = OpenFiles[val1].fpos
		local last  = OpenFiles[val1].fpos + LINE_LEN
		local s = string.sub(Files[number][drive][fname], first, last)
		if s then
			s = s:gmatch("[^\n]+")()
			if s then
				local size = string.len(s)
				OpenFiles[val1].fpos = OpenFiles[val1].fpos + size + 1
				vm16.write_ascii(pos, val2, s.."\000")
				return size
			end
		end
		return 0
	end
	return 65535
end

local function write_file(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	if OpenFiles[val1] then
		local number = OpenFiles[val1].number
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		Files[number][drive][fname] = SharedMemory[number]
		SharedMemory[number] = nil
		return 1
	end
	return 0
end

local function write_line(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local s = vm16.read_ascii(pos, val2, LINE_LEN)
	if s and OpenFiles[val1] then
		local number = OpenFiles[val1].number
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		local t = Files[number][drive] 
		if t[fname] == "" then
			t[fname] = s
		else
			t[fname] = t[fname].."\n"..s
		end
		return 1
	end
	return 0
end
	
local function file_size(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive, fname = filename(s)
	if drive then
		if Files[number] and Files[number][drive] and Files[number][drive][fname] then
			return string.len(Files[number][drive][fname])
		end
	end
	return 0
end

local function list_files(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive, fname = filespattern(s)
	if drive then
		local t = {}
		local total_size = 0
		Files[number] = Files[number] or {}
		Files[number][drive] = Files[number][drive] or {}
		local pattern = gen_pattern(fname)
		for name,str in pairs(Files[number][drive]) do
			local size = string.len(str)
			total_size = total_size + size
			if fmatch(name, pattern) then
				t[#t+1] = string.format("%-12s  %5u", name, kbyte(size))
			end
		end
		t[#t+1] = string.format("%u/%u files  %u/%u kBytes", 
				#t, max_num_files(drive), kbyte(total_size), max_fs_size(drive))
		SharedMemory[number] = t
		return #t - 1
	end
	SharedMemory[number] = nil
	return 0
end

local function remove_files(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive, fname = filespattern(s)
	if drive then
		local t = {}
		if Files[number] and Files[number][drive] then
			local pattern = gen_pattern(fname)
			for name,str in pairs(Files[number][drive]) do
				if fmatch(name, pattern) then
					t[#t+1] = name
				end
			end
			for _,name in ipairs(t) do
				Files[number][drive][name] = nil
			end
			return #t
		end
	end
	return 0
end

local function copy_file(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s1 = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive1, fname1 = filename(s1)
	local s2 = vm16.read_ascii(pos, val2, FILE_NAME_LEN)
	local drive2, fname2 = filename(s2)
	if drive1 and drive2 then
		if Files[number] and Files[number][drive1] and Files[number][drive2] then
			Files[number][drive2][fname2] = Files[number][drive1][fname1]
			return 1
		end
	end
	return 0
end

local function move_file(pos, address, val1, val2)
	if M(pos):get_int("rom_size") < OS_ENA then
		return 0
	end
	
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s1 = vm16.read_ascii(pos, val1, FILE_NAME_LEN)
	local drive1, fname1 = filename(s1)
	local s2 = vm16.read_ascii(pos, val2, FILE_NAME_LEN)
	local drive2, fname2 = filename(s2)
	if drive1 and drive2 then
		if Files[number] and Files[number][drive1] and Files[number][drive2] then
			Files[number][drive2][fname2] = Files[number][drive1][fname1]
			Files[number][drive1][fname1] = nil
			return 1
		end
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| File System    | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $50   fopen            @fname  -     fp
 $51   fclose           fp      -     1=ok
 $52   read_file        fp      -     1=ok
 $53   read_line        fp     @dest  1=ok
 $54   write_file       fp      -     1=ok
 $55   write_line       fp     @text  1=ok    
 $56   file_size        @fname  -     size
 $57   list_files       @fname  -     1=ok
 $58   remove_files     @fname  -     num
 $59   copy_file        @from  @to    1=ok
 $5A   move_file        @from  @to    1=ok
 ]]

pdp13.register_SystemHandler(0x50, fopen, help)
pdp13.register_SystemHandler(0x51, fclose)
pdp13.register_SystemHandler(0x52, read_file)
pdp13.register_SystemHandler(0x53, read_line)
pdp13.register_SystemHandler(0x54, write_file)
pdp13.register_SystemHandler(0x55, write_line)
pdp13.register_SystemHandler(0x56, file_size)
pdp13.register_SystemHandler(0x57, list_files)
pdp13.register_SystemHandler(0x58, remove_files)
pdp13.register_SystemHandler(0x59, copy_file)
pdp13.register_SystemHandler(0x5A, move_file)
