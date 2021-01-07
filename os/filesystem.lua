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
local OpenFiles = {}  -- {fpos, uid, drive, fname}
local OpenFilesRef = 1

local function fsize(fname)
	local f = io.open(WP..fname, "rb")
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
		if uid and fname then
			Files[uid] = Files[uid] or {}
			Files[uid][fname] = fsize(name)
		end
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
		return uid
	elseif drive == 'h' then
		local uid = M(pos):get_string("uid_h")
		if uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
			M(pos):set_string("uid_h", uid)
		end
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
		return uid
	elseif drive == 'h' then
		if not uid or uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
		end
		M(pos):set_string("uid_h", uid)
		return uid
	end
end

local function read_file_real(uid, fname)
	local f = io.open(WP..uid.."_"..fname, "rb")
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
		local f = io.open(path, "wb")
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
	local mem = techage.get_nvm(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s, mem.current_drive)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		
		if mounted and Files[uid] then
			if val2 == 119 then -- 'w' for write
				Files[uid][fname] = ""
			elseif Files[uid][fname] then
				Files[uid][fname] = read_file_real(uid, fname) or ""
			else
				return 0
			end
			if not OpenFiles[OpenFilesRef] then
				OpenFiles[OpenFilesRef] = {fpos = 1, uid = uid, drive = drive, fname = fname}
				OpenFilesRef = OpenFilesRef + 1
				return OpenFilesRef - 1
			end
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

-- Read into pipe to be used by other sys commands
local function read_file(pos, address, val1, val2)
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		local items = pdp13.text2table(Files[uid][fname])
		pdp13.push_pipe(pos, items)
		return 1
	end
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
				vm16.write_ascii(pos, val2, s)
				return size
			end
		end
		return 0
	end
	return 65535
end

-- Write from shared memory, prepared by other sys commands
local function write_file(pos, address, val1, val2)
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		local items = pdp13.pop_pipe(pos, pdp13.MAX_PIPE_LEN)
		if uid and fname and items then
			Files[uid][fname] = table.concat(items, "\n")
			return 1
		end
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
	local mem = techage.get_nvm(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filename(s, mem.current_drive)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1

		if mounted and Files[uid] then
			return tonumber(Files[uid][fname]) or 0
		end
	end
	return 0
end

local function list_files(pos, address, val1, val2)
	local order = function(a, b)
		local base1, ext1 = unpack(string.split(a, ".", false, 1))
		local base2, ext2 = unpack(string.split(b, ".", false, 1))
		ext1 = ext1 or ""
		ext2 = ext2 or ""
		if ext1 ~= ext2 then
			return ext1 < ext2
		else
			return base1 < base2
		end
	end
	
	local mem = techage.get_nvm(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s, mem.current_drive)
	local uid = get_uid(pos, drive)
	local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1

	if mounted and Files[uid] then
		local t = {}
		local total_size = 0
		local pattern = gen_filepattern(fname)
		
		for name,str in pairs(Files[uid]) do
			if fmatch(name, pattern) then
				local size = tonumber(str) or 0
				total_size = total_size + size
				t[#t+1] = string.format("%-12s  %4s", name, kbyte(size))
			end
		end
		table.sort(t, function(a,b) return order(a, b) end)
		t = pdp13.table_2rows(t, "     ")
		t[#t+1] = string.format("%u/%u files  %s/%uK", 
				#t, max_num_files(drive), kbyte(total_size), max_fs_size(drive))
		pdp13.push_pipe(pos, t)
		return #t - 1
	end
	return 0
end

local function remove_files(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive, fname = filespattern(s, mem.current_drive)
	local uid = get_uid(pos, drive)
	local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1

	if mounted and Files[uid] then
		local t = {} -- For post-deletion
		local pattern = gen_filepattern(fname)
		
		for name,_ in pairs(Files[uid]) do
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
	local mem = techage.get_nvm(pos)
	
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1, mem.current_drive)
	local uid1 = get_uid(pos, drive1)
	local mounted1 = drive1 == 'h' or M(pos):get_int("mounted_t") == 1
	
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2, mem.current_drive)
	local uid2 = get_uid(pos, drive2)
	local mounted2 = drive2 == 'h' or M(pos):get_int("mounted_t") == 1

	if drive1 and drive2 and mounted1 and mounted2 then
		if Files[uid1] and Files[uid1][fname1] and Files[uid2] then
			Files[uid2][fname2] = Files[uid1][fname1]
			local s = read_file_real(uid1, fname1)
			write_file_real(uid2, fname2, s)
			return 1
		end
	end
	return 0
end

local function move_file(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_FNAME_LEN)
	local drive1, fname1 = filename(s1, mem.current_drive)
	local uid1 = get_uid(pos, drive1)
	local mounted1 = drive1 == 'h' or M(pos):get_int("mounted_t") == 1
	
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_FNAME_LEN)
	local drive2, fname2 = filename(s2, mem.current_drive)
	local uid2 = get_uid(pos, drive2)
	local mounted2 = drive2 == 'h' or M(pos):get_int("mounted_t") == 1
	
	if drive1 and drive2 and mounted1 and mounted2 then
		if Files[uid1] and Files[uid1][fname1] and Files[uid2] then
			Files[uid2][fname2] = Files[uid1][fname1]
			Files[uid1][fname1] = nil
			local s = read_file_real(uid1, fname1)
			write_file_real(uid2, fname2, s)
			remove_file_real(uid1, fname1)
			return 1
		end
	end
	return 0
end

local function change_dir(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local drive = string.char(val1)
	if drive == "t" or drive == "h" then
		mem.current_drive = drive
		return 1
	end
	return 0
end

local function read_word(pos, address, val1, val2)
	if OpenFiles[val1] then
		local uid = OpenFiles[val1].uid
		local fname = OpenFiles[val1].fname
		local idx = OpenFiles[val1].fpos
		local s = string.sub(Files[uid][fname], idx, idx+1)
		if s then
			OpenFiles[val1].fpos = OpenFiles[val1].fpos + 2
			local val = string.byte(s, 1) + string.byte(s, 2) * 256
			return val
		end
		return 65535
	end
	return 65535
end

local help = [[+-----+----------------+-------------+------+
|sys #| File System    | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $50   file open        @fname  mode  fref
 $51   file close       fref    -     1=ok
 $52   read file (>p)   fref    -     1=ok
 $53   read line        fref   @dest  1=ok
 $54   write file (<p)  fref    -     1=ok
 $55   write line       fref   @text  1=ok    
 $56   file size        @fname  -     size
 $57   list files (>p)  @fname  -     num f
 $58   remove files     @fname  -     num f
 $59   copy file        @from  @to    1=ok
 $5A   move file        @from  @to    1=ok
 $5B   change dir       drive         1=ok
 $5C   read word        fref          word]]

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
pdp13.register_SystemHandler(0x5C, read_word)


function pdp13.init_filesystem(pos, has_tape, has_hdd)
	if has_tape then
		local uid = get_uid(pos, "t")
		Files[uid] = Files[uid] or {}
		write_file_real(uid, "pipe.sys", uid)
	end
	if has_hdd then
		local uid = get_uid(pos, "h")
		Files[uid] = Files[uid] or {}
		write_file_real(uid, "pipe.sys", uid)
	end
end

function pdp13.mount_drive(pos, drive, mount)
	if drive == "t" then
		M(pos):set_int("mounted_t", mount == true and 1 or 0)
	end
end
	
pcall(scan_file_system)

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------
-- pdp13.get_uid(pos, drive)
pdp13.get_uid = get_uid
-- pdp13.set_uid(pos, drive, uid)
pdp13.set_uid = set_uid


function pdp13.real_file_path(pos, file_name)
	local mem = techage.get_nvm(pos)
	local drive, _ = filename(file_name, mem.current_drive)
	if drive then
		local uid = get_uid(pos, drive)
		return WP..uid.."_"
	end
end

function pdp13.real_file_filename(pos, file_name)
	local mem = techage.get_nvm(pos)
	local drive, fname = filename(file_name, mem.current_drive)
	if drive then
		local uid = get_uid(pos, drive)
		return WP..uid.."_"..fname
	end
end

function pdp13.file_exists(pos, file_name)
	file_name = pdp13.real_file_filename(pos, file_name)
	local f = io.open(file_name, "r")
	if f ~= nil then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

function pdp13.read_file(pos, fref)
	if OpenFiles[fref] then
		local uid = OpenFiles[fref].uid
		local fname = OpenFiles[fref].fname
		return Files[uid][fname]
	end
end

function pdp13.write_file(pos, fref, s)
	if OpenFiles[fref] then
		local uid = OpenFiles[fref].uid
		local fname = OpenFiles[fref].fname
		Files[uid][fname] = s
		return true
	end
end

function pdp13.make_file_visible(pos, file_name)
	local mem = techage.get_nvm(pos)
	local drive, fname = filename(file_name, mem.current_drive)
	if drive then
		local uid = get_uid(pos, drive)
		local s = read_file_real(uid, fname)
		if s then
			Files[uid] = Files[uid] or {}
			Files[uid][fname] = string.len(s)
		end
	end
end