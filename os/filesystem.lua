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
local S2T = function(s) return minetest.deserialize(s) or {} end
local T2S = function(t) return minetest.serialize(t) or 'return {}' end

local gen_filepattern = pdp13.gen_filepattern
local fmatch = pdp13.fmatch
local filename = pdp13.filename
local filespattern = pdp13.filespattern
local max_num_files = pdp13.max_num_files
local max_fs_size = pdp13.max_fs_size
local kbyte = pdp13.kbyte

local Files = pdp13.Files
local SharedMemory = {} -- used for large text chunks or tables of strings
local OpenFiles = {}
local OpenFilesRef = 1

pdp13.SharedMemory = SharedMemory

local function fopen(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s)
	print("fopen", drive, fname)
	if drive and Files[number] and Files[number][drive] then
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
	print("fclose")
	if OpenFiles[val1] then
		OpenFiles[val1] = nil
		return 1
	end
	return 0
end

local function read_file(pos, address, val1, val2)
	print("read_file")
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
	print("read_line")
	if OpenFiles[val1] then
		local number = OpenFiles[val1].number
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		local first = OpenFiles[val1].fpos
		local last  = OpenFiles[val1].fpos + pdp13.MAX_LINE_LEN
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
	print("write_file")
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
	local s = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)
	print("write_line", s)
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
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s)
	print("file_size", drive, fname)
	if drive and Files[number] and Files[number][drive] then
		return string.len(Files[number][drive][fname] or "")
	end
	return 0
end

local function list_files(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s)
	print("list_files", drive, fname, dump(Files[number]))
	if drive and Files[number] and Files[number][drive] then
		local t = {}
		local total_size = 0
		local pattern = gen_filepattern(fname)
		for name,str in pairs(Files[number][drive]) do
			local size = string.len(str)
			total_size = total_size + size
			if fmatch(name, pattern) then
				t[#t+1] = string.format("%-12s  %5u", name, kbyte(size))
			end
		end
		t[#t+1] = string.format("%u/%u files  %u/%u K", 
				#t, max_num_files(drive), kbyte(total_size), max_fs_size(drive))
		SharedMemory[number] = t
		return #t - 1
	end
	SharedMemory[number] = nil
	return 0
end

local function remove_files(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s)
	print("remove_files", drive, fname)
	if drive and Files[number] and Files[number][drive] then
		local t = {}
		local pattern = gen_filepattern(fname)
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
	return 0
end

local function copy_file(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1)
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2)
	print("copy files", drive1, fname1, drive2, fname2)
	if drive1 and drive2 then
		if Files[number] and Files[number][drive1] and Files[number][drive2] then
			Files[number][drive2][fname2] = Files[number][drive1][fname1]
			return 1
		end
	end
	return 0
end

local function move_file(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1)
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2)
	print("copy files", drive1, fname1, drive2, fname2)
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
 $50   file open        @fname  -     fref
 $51   file close       fref    -     1=ok
 $52   read file (>SM)  fref    -     1=ok
 $53   read line        fref   @dest  1=ok
 $54   write file (<SM) fref    -     1=ok
 $55   write line       fref   @text  1=ok    
 $56   file size        @fname  -     size
 $57   list files (>SM) @fname  -     num f
 $58   remove files     @fname  -     num f
 $59   copy file        @from  @to    1=ok
 $5A   move file        @from  @to    1=ok
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


function pdp13.init_filesystem(pos, has_tape, has_hdd)
	print("init_filesystem", has_tape, has_hdd)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	
	Files[number] = Files[number] or {}
	if has_tape then
		Files[number][pdp13.TAPE_NUM] = Files[number][pdp13.TAPE_NUM] or {}
	else
		Files[number][pdp13.TAPE_NUM] = nil
	end
	if has_hdd then
		Files[number][pdp13.HDD_NUM] = Files[number][pdp13.HDD_NUM] or {}
	else
		Files[number][pdp13.HDD_NUM] = nil
	end
end

-- drive is 1 (HDD) or 2 (tape)
-- function returns a string
function pdp13.get_filesystem(pos, drive)
	print("get_filesystem")
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	if number then
		Files[number] = Files[number] or {}
		return T2S(Files[number][drive])
	end
end

function pdp13.set_filesystem(pos, drive, str)
	print("set_filesystem")
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	if number then
		Files[number] = Files[number] or {}
		Files[number][drive] = S2T(str)
	end
end