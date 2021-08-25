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

local MP = minetest.get_modpath("pdp13")
local backend = dofile(MP .. "/os/fs_backend.lua")
local mpath = pdp13.path

local Files = pdp13.Files
local OpenFiles = {}  -- {fpos, uid, drive, dir, fname, data}
local OpenFilesRef = 1

local function fopen(pos, address, val1, val2)
	--print("fopen")
	local mem = techage.get_nvm(pos)
	local path = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	local drive, dir, fname = mpath.splitpath(mem, path)
	local data = ""
	if drive then
		local uid = pdp13.get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		
		if mounted and Files[uid] and Files[uid][dir] then
			if val2 == 119 then -- 'w' for write
				data = ""
			elseif Files[uid][dir][fname] then
				local abspath = mpath.join_be(dir, fname)
				data = backend.read_file(uid, abspath) or ""
			else
				return 0
			end
			if not OpenFiles[OpenFilesRef] then
				OpenFiles[OpenFilesRef] = {
					fpos = 1, 
					uid = uid, 
					drive = drive, 
					dir = dir, 
					fname = fname, 
					data = data}
				OpenFilesRef = OpenFilesRef + 1
				return OpenFilesRef - 1
			end
		end
	end
	return 0
end

local function fclose(pos, address, val1)
	local r = OpenFiles[val1]
	if r then
		local size = string.len(r.data)
		local total_num, total_size = pdp13.total_num_and_size(pos, r.drive)
		if total_size + size <= (pdp13.max_filesystem_size(r.drive) * 1024) and 
				total_num <= pdp13.max_num_files(r.drive) then
			local abspath = mpath.join_be(r.dir, r.fname)
			backend.write_file(r.uid, abspath, r.data or "")
			minetest.log("warning", "[PDP13] fclose.size = " .. size or 0)
			Files[r.uid][r.dir][r.fname] = size
			OpenFiles[val1] = nil
			return 1
		end
		minetest.log("warning", "[PDP13] Platte voll")
		Files[r.uid][r.dir][r.fname] = nil
		OpenFiles[val1] = nil
	end
	return 0
end

-- Read into pipe to be used by other sys commands
local function read_file(pos, address, val1, val2)
	local r = OpenFiles[val1]
	if r then
		local items = pdp13.text2table(r.data)
		pdp13.push_pipe(pos, items)
		return 1
	end
	return 0
end

local function read_line(pos, address, val1, val2)
	local r = OpenFiles[val1]
	if r then
		local first = r.fpos
		local last  = r.fpos + pdp13.MAX_LINE_LEN
		local s = string.sub(r.data, first, last)
		if s then
			s = s:gmatch("[^\n]+")()
			if s then
				local size = string.len(s)
				r.fpos = r.fpos + size + 1
				vm16.write_ascii(pos, val2, s)
				return size
			end
		end
		return 0
	end
	return 0
end

local function read_word(pos, address, val1, val2)
	local r = OpenFiles[val1]
	if r then
		local idx = r.fpos
		local s = string.sub(r.data, idx, idx+1)
		if s then
			r.fpos = idx + 2
			return string.byte(s, 1) + string.byte(s, 2) * 256
		end
		return 65535
	end
	return 65535
end

-- Write from shared memory, prepared by other sys commands
local function write_file(pos, address, val1, val2)
	local r = OpenFiles[val1]
	if r then
		local items = pdp13.pop_pipe(pos, pdp13.MAX_PIPE_LEN)
		r.data = table.concat(items, "\n")
		return 1
	end
	return 0
end

local function write_line(pos, address, val1, val2)
	local r = OpenFiles[val1]
	if r then
		local s = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)
		if s then
			if r.data == "" then
				r.data = s
			else
				r.data = r.data .. "\n" .. s
			end
			return 1
		end
	end
	return 0
end
	
local function file_size(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	return pdp13.file_size(pos, path)
end

local function list_files(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	local files = pdp13.list_files(pos, path)
	return pdp13.pipe_filelist(pos, path, files)
end

local function remove_files(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	return pdp13.remove_files(pos, path)
end

local function copy_file(pos, address, val1, val2)
	local path1 = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	local path2 = vm16.read_ascii(pos, val2, mpath.MAX_PATH_LEN)
	return pdp13.copy_file(pos, path1, path2) and 1 or 0
end

local function move_file(pos, address, val1, val2)
	local path1 = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	local path2 = vm16.read_ascii(pos, val2, mpath.MAX_PATH_LEN)
	return pdp13.move_file(pos, path1, path2) and 1 or 0
end

local function change_drive(pos, address, val1, val2)
	local drive = string.char(val1)
	return pdp13.change_drive(pos, drive) and 1 or 0
end

local function change_dir(pos, address, val1, val2)
	local dir = vm16.read_ascii(pos, val1, mpath.MAX_DIR_LEN)
	return pdp13.change_dir(pos, dir) and 1 or 0
end

local function get_current_drive(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	return string.byte(mem.curr_drive or "t", 1)
end

local function get_current_dir(pos, address, val1, val2)
	local mem = techage.get_mem(pos)
	vm16.write_ascii(pos, val1, mem.curr_dir or "")
	return 1
end

local function make_dir(pos, address, val1, val2)
	local dir = vm16.read_ascii(pos, val1, mpath.MAX_DIR_LEN)
	return pdp13.make_dir(pos, dir) and 1 or 0
end

local function remove_dir(pos, address, val1, val2)
	local dir = vm16.read_ascii(pos, val1, mpath.MAX_DIR_LEN)
	return pdp13.remove_dir(pos, dir) and 1 or 0
end

local function get_files(pos, address, val1, val2)
	local path = vm16.read_ascii(pos, val1, mpath.MAX_PATH_LEN)
	local uid, dir, t1, t2 = pdp13.get_files(pos, path)
	if t2 then
		pdp13.push_pipe(pos, t2)
		return #t2 > 0 and 1 or 0
	end
	return 0
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
 $5B   change drive     drive   -     1=ok
 $5C   read word        fref    -     word
 $5D   change dir       @dir    -     1=ok 
 $5E   cur_drive         -      -     drive
 $5F   cur_dir          @dest   -     1=ok
 $60   make dir         @dir    -     1=ok
 $61   remove dir       @dir    -     1=ok
 $62   get files (>p)   @fname  -     1=ok
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
pdp13.register_SystemHandler(0x5B, change_drive)
pdp13.register_SystemHandler(0x5C, read_word)
pdp13.register_SystemHandler(0x5D, change_dir)
pdp13.register_SystemHandler(0x5E, get_current_drive)
pdp13.register_SystemHandler(0x5F, get_current_dir)
pdp13.register_SystemHandler(0x60, make_dir)
pdp13.register_SystemHandler(0x61, remove_dir)
pdp13.register_SystemHandler(0x62, get_files)

vm16.register_sys_cycles(0x52, 10000)
vm16.register_sys_cycles(0x54, 10000)
vm16.register_sys_cycles(0x57, 10000)
vm16.register_sys_cycles(0x58, 10000)
vm16.register_sys_cycles(0x59, 10000)
vm16.register_sys_cycles(0x5A, 10000)
vm16.register_sys_cycles(0x60, 10000)
vm16.register_sys_cycles(0x61, 10000)
vm16.register_sys_cycles(0x62, 10000)
