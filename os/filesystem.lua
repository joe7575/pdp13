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

local WP = minetest.get_worldpath() .. "/pdp13/"  -- to store the files
local gen_filepattern = pdp13.gen_filepattern
local fmatch = pdp13.fmatch
local filename = pdp13.filename
local filespattern = pdp13.filespattern
local max_num_files = pdp13.max_num_files
local max_fs_size = pdp13.max_fs_size
local kbyte = pdp13.kbyte

local Files = {}  -- t[uid][fname] = filesize
local SharedMemory = {} -- used for large text chunks or tables of strings
local OpenFiles = {}  -- {fpos, uid, drive, fname}
local OpenFilesRef = 1

local function fsize(fname)
	local f = io.open(WP..fname, "r")
	if f then
		local size = f:seek("end")
		f:close()
		return size
	end
	return 0
end

-- Generate a list in memory with all files
local function scan_file_system()
	-- For the case it doesn't exist
	minetest.mkdir(WP)
	
	for _,name in ipairs(minetest.get_dir_list(WP, false)) do
		local uid, fname = unpack(string.split(name, "_", false, 1))
		Files[uid] = Files[uid] or {}
		Files[uid][fname] = fsize(name)
	end
end

-- Take meta ID or generate a new one
local function get_uid(pos, drive)
	if drive == 't' then
		local uid = M(pos):get_string("uid_t")
		if uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
			M(pos):set_string("uid_t", uid)
		end
		-- Defensive programming
		pdp13.UIDCounter = math.max(pdp13.UIDCounter, uid)
		return uid
	elseif drive == 'h' then
		local uid = M(pos):get_string("uid_h")
		if uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
			M(pos):set_string("uid_h", uid)
		end
		-- Defensive programming
		pdp13.UIDCounter = math.max(pdp13.UIDCounter, uid)
		return uid
	end
end

local function set_uid(pos, drive, uid)
	if drive == 't' then
		if not uid or uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
		end
		M(pos):set_string("uid_t", uid)
		-- Defensive programming
		pdp13.UIDCounter = math.max(pdp13.UIDCounter, uid)
		return uid
	elseif drive == 'h' then
		if not uid or uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
		end
		M(pos):set_string("uid_h", uid)
		-- Defensive programming
		pdp13.UIDCounter = math.max(pdp13.UIDCounter, uid)
		return uid
	end
end

local function read_file_real(uid, fname)
	local f = io.open(WP..uid.."_"..fname, "r")
	if f then
		local s = f:read("*all")
		f:close()
		return s
	end
end
	
local function write_file_real(uid, fname, s)
	local path = WP..uid.."_"..fname
	-- Consider unit test
	if not pcall(minetest.safe_file_write, path, s) then
		local f = io.open(path, "w+")
		if f then
			f:write(s)
			f:close()
			return true
		end
	end
end

local function remove_file_real(uid, fname)
	os.remove(WP..uid.."_"..fname)
end

-- Size of all files of one drive
local function total_size(tDirectory)
	local size = 0
	for _,v in pairs(tDirectory or {}) do
		size = size + (tonumber(v) or 0)
	end
	return size
end

local function fopen(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s, mem.current_drive)
	local uid = get_uid(pos, drive)
	
	if uid and Files[uid] then
		if val2 == 119 then -- 'w' for write
			Files[uid][fname] = ""
		else
			Files[uid][fname] = read_file_real(uid, fname) or ""
		end
		if not OpenFiles[OpenFilesRef] then
			OpenFiles[OpenFilesRef] = {fpos = 1, uid = uid, drive = drive, fname = fname}
			OpenFilesRef = OpenFilesRef + 1
			return OpenFilesRef - 1
		end
	end
	return 0
end

local function fclose(pos, address, val1)
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local drive = OpenFiles[val1].drive
		local fname = OpenFiles[val1].fname
		local s = Files[uid][fname] or ""
		local size = string.len(s)
		if total_size(Files[uid]) + size <= (pdp13.max_fs_size(drive) * 1024) then
			write_file_real(uid, fname, s)
			Files[uid][fname] = size
			OpenFiles[val1] = nil
			return 1
		end
		Files[uid][fname] = nil
		OpenFiles[val1] = nil
	end
	return 0
end

-- Read into shared memory for to be used by other sys commands
local function read_file(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		SharedMemory[number] = Files[uid][fname]
		return 1
	end
	SharedMemory[number] = nil
	return 0
end

local function read_line(pos, address, val1, val2)
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		local first = OpenFiles[val1].fpos
		local last  = OpenFiles[val1].fpos + pdp13.MAX_LINE_LEN
		local s = string.sub(Files[uid][fname], first, last)
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

-- Write from shared memory, prepared by other sys commands
local function write_file(pos, address, val1, val2)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		Files[uid][fname] = SharedMemory[number]
		SharedMemory[number] = nil
		return 1
	end
	return 0
end

local function write_line(pos, address, val1, val2)
	local s = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)

	if s and OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		local t = Files[uid]
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
	local mem = techage.get_mem(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s, mem.current_drive)
	local uid = get_uid(pos, drive)
	
	if drive and Files[uid] then
		return tonumber(Files[uid][fname]) or 0
	end
	return 0
end

local function list_files(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	local number = M(pos):get_string("node_number")
	number = tonumber(number)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s, mem.current_drive)
	local uid = get_uid(pos, drive)
	
	if drive and Files[uid] then
		local t = {}
		local total_size = 0
		local pattern = gen_filepattern(fname)
		
		for name,str in pairs(Files[uid]) do
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
	local mem = techage.get_mem(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s, mem.current_drive)
	local uid = get_uid(pos, drive)

	if drive and Files[uid] then
		local t = {} -- For post-deletion
		local pattern = gen_filepattern(fname)
		
		for name,str in pairs(Files[uid]) do
			if fmatch(name, pattern) then
				t[#t+1] = name
			end
		end
		for _,name in ipairs(t) do
			Files[uid][name] = nil
			remove_file_real(uid, name)
		end
		return #t
	end
	return 0
end

local function copy_file(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1, mem.current_drive)
	local uid1 = get_uid(pos, drive1)
	
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2, mem.current_drive)
	local uid2 = get_uid(pos, drive2)

	if drive1 and drive2 then
		if Files[uid1] and Files[uid1][fname1] and Files[uid2] then
			Files[uid2][fname2] = Files[uid1][fname1]
			return 1
		end
	end
	return 0
end

local function move_file(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1, mem.current_drive)
	local uid1 = get_uid(pos, drive1)
	
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2, mem.current_drive)
	local uid2 = get_uid(pos, drive2)
	
	if drive1 and drive2 then
		if Files[uid1] and Files[uid1][fname1] and Files[uid2] then
			Files[uid2][fname2] = Files[uid1][fname1]
			Files[uid1][fname1] = nil
			remove_file_real(uid1, fname1)
			return 1
		end
	end
	return 0
end

local function change_dir(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	local drive = string.char(val1)
	if drive == "t" or drive == "h" then
		mem.current_drive = drive
		return 1
	end
	return 0
end


local help = [[+-----+----------------+-------------+------+
|sys #| File System    | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $50   file open        @fname  mode  fref
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
 $5B   change dir       drive         1=ok
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
pdp13.register_SystemHandler(0x5B, change_dir)


function pdp13.init_filesystem(pos, has_tape, has_hdd)
	if has_tape then
		local uid = get_uid(pos, "t")
		Files[uid] = Files[uid] or {}
	end
	if has_hdd then
		local uid = get_uid(pos, "h")
		Files[uid] = Files[uid] or {}
	end
end

pcall(scan_file_system)

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------
pdp13.SharedMemory = SharedMemory
-- pdp13.get_uid(pos, drive)
pdp13.get_uid = get_uid
-- pdp13.set_uid(pos, drive, uid)
pdp13.set_uid = set_uid