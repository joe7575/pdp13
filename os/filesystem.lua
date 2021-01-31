--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 File System for tape drive and hard disk

]]--

-- On file system level, we always work with fname strings, 
-- which could include drive or dir information, but not
-- with uids or real file paths!

-- for lazy programmers
local M = minetest.get_meta
local MP = minetest.get_modpath("pdp13")

local Files = {}  -- t[uid][dir][fname] = file_size
local mpath = pdp13.path
local backend = dofile(MP .. "/os/fs_backend.lua")

pdp13.path = mpath -- make it global available

local function kbyte(val)
	if val > 9999 then
		return tostring(math.floor(val / 1024) + 1).."K"
	else
		return tostring(val)
	end
end

local function max_num_files(drive)
	if drive == "h" then
		return 512
	else
		return 64
	end
end
	
local function max_filesystem_size(drive)
	if drive == "h" then
		return 500  -- kByte
	else
		return 60  -- kByte
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
		--print("get_uid_t", uid)
		return uid
	elseif drive == 'h' then
		local uid = M(pos):get_string("uid_h")
		if uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
			M(pos):set_string("uid_h", uid)
		end
		--print("get_uid_h", uid)
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
		--print("set_uid_t", uid)
		return uid
	elseif drive == 'h' then
		if not uid or uid == "" then
			pdp13.UIDCounter = pdp13.UIDCounter + 1
			uid = string.format("%08X", pdp13.UIDCounter)
		end
		M(pos):set_string("uid_h", uid)
		--print("set_uid_h", uid)
		return uid
	end
end

local function del_uid(pos, drive)
	if drive == 't' then
		M(pos):set_string("uid_t", nil)
	elseif drive == 'h' then
		M(pos):set_string("uid_h", nil)
	end
end

local function scan_file_system()	
	for _, item in ipairs(backend.scan_file_system()) do
		-- dir$fname is used for dir/fname
		local t = string.split(item.path, "$", false, 1)
		local uid, dir, fname
		if #t == 2 then
			uid, dir, fname = item.uid, t[1], t[2]
		else
			uid, dir, fname = item.uid, "", item.path
		end
		Files[uid] = Files[uid] or {}
		Files[uid][dir] = Files[uid][dir] or {}
		Files[uid][dir][fname] = item.size
	end
end

pcall(scan_file_system)

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------
pdp13.get_uid = get_uid
pdp13.set_uid = set_uid
pdp13.del_uid = del_uid
pdp13.kbyte = kbyte
pdp13.max_num_files = max_num_files
pdp13.max_filesystem_size = max_filesystem_size
pdp13.Files = Files

-- Size and number of all dirs/files of one drive
function pdp13.total_num_and_size(pos, drive)
	local uid = get_uid(pos, drive)
	local total_num = -1
	local total_size = 0
	for dir, item in pairs(Files[uid] or {}) do
		total_num = total_num + 1
		for name, size in pairs(item) do
			total_num = total_num + 1
			total_size = total_size + (tonumber(size) or 0)
		end
	end
	return total_num, total_size
end

-- Return  uid, dir, list of filenames, and list of full pathnames
function pdp13.get_files(pos, path)
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	local uid = get_uid(pos, drive)
	local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
	
	--print("get_files", uid, drive, mounted)
	if uid and mounted and Files[uid] and Files[uid][dir] then
		local t1 = {}
		local t2 = {}
		local pattern = mpath.gen_filepattern(fname)
		
		for fname,_ in pairs(Files[uid][dir]) do
			if mpath.filename_match(fname, pattern) then
				t1[#t1+1] = fname
				t2[#t2+1] = drive .. "/" .. mpath.join_fe(dir, fname)
			end
		end
		if dir == "" then
			for fname,_ in pairs(Files[uid]) do
				--print("dir", fname)
				if mpath.filename_match(fname, pattern) then
					t1[#t1+1] = "*" .. fname .. "/"
				end
			end
		end
		return uid, dir, t1, t2
	end
end

function pdp13.list_files(pos, path)
	local order = function(a, b)
		local _, _, base1, ext1 = string.find(a, "(.+)%.(.*)")
		local _, _, base2, ext2 = string.find(b, "(.+)%.(.*)")
		ext1 = ext1 or ""
		ext2 = ext2 or ""
		base1 = base1 or a
		base2 = base2 or b
		--print(base1, ext1, base2, ext2)
		if ext1 ~= ext2 then
			return ext1 < ext2
		else
			return base1 < base2
		end
	end
	
	local uid, dir, files = pdp13.get_files(pos, path)
	if files then
		local t = {}
		local ref = Files[uid][dir]
		table.sort(files, function(a,b) return order(a, b) end)
		
		for _, fname in ipairs(files) do
			local size = tonumber(ref[fname]) or 5
			t[#t+1] = string.format("%-12s  %4s", fname, kbyte(size))
		end
		return t
	end
end	

function pdp13.pipe_filelist(pos, path, files)
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	local total_num, total_size = pdp13.total_num_and_size(pos, drive)
	if files then
		files = pdp13.table_2rows(files, "     ")
		files[#files+1] = string.format("%u/%u files  %s/%uK", 
				#files, pdp13.max_num_files(drive), 
				kbyte(total_size), max_filesystem_size(drive))
		pdp13.push_pipe(pos, files)
		return #files - 1
	end
	return 0
end	
	
function pdp13.remove_files(pos, path)
	local uid, dir, files = pdp13.get_files(pos, path)
	if files then
		local ref = Files[uid][dir]
			
		for _,fname in ipairs(files) do
			Files[uid][dir][fname] = nil
			local abspath = mpath.join_be(dir, fname)
			backend.remove_file(uid, abspath)
		end
		return #files
	end
	return 0
end

function pdp13.copy_file(pos, path1, path2)
	local mem = techage.get_nvm(pos)
	
	--print("copy_file", path1, path2)
	local drive1, dir1, fname1 = mpath.splitpath(mem, path1)
	local uid1 = get_uid(pos, drive1)
	local mounted1 = drive1 == 'h' or M(pos):get_int("mounted_t") == 1
	
	local drive2, dir2, fname2 = mpath.splitpath(mem, path2)
	if fname2 == "" then fname2 = fname1 end
	local uid2 = get_uid(pos, drive2)
	local mounted2 = drive2 == 'h' or M(pos):get_int("mounted_t") == 1

	print("copy_file", drive1, dir1, fname1, drive2, dir2, fname2)
	if drive1 and drive2 and mounted1 and mounted2 then
		if Files[uid1] and Files[uid1][dir1] and Files[uid2] and Files[uid2][dir2] then
			Files[uid2][dir2][fname2] = Files[uid1][dir1][fname1]
			local abspath1 = mpath.join_be(dir1, fname1)
			local abspath2 = mpath.join_be(dir2, fname2)
			local s = backend.read_file(uid1, abspath1)
			backend.write_file(uid2, abspath2, s)
			return true
		end
	end
end

function pdp13.move_file(pos, path1, path2)
	local mem = techage.get_nvm(pos)
	
	local drive1, dir1, fname1 = mpath.splitpath(mem, path1)
	local uid1 = get_uid(pos, drive1)
	local mounted1 = drive1 == 'h' or M(pos):get_int("mounted_t") == 1
	
	local drive2, dir2, fname2 = mpath.splitpath(mem, path2)
	local uid2 = get_uid(pos, drive2)
	local mounted2 = drive2 == 'h' or M(pos):get_int("mounted_t") == 1
	
	if drive1 and drive2 and mounted1 and mounted2 then
		if Files[uid1] and Files[uid1][dir1] and Files[uid2] and Files[uid2][dir2] then
			Files[uid2][dir2][fname2] = Files[uid1][dir1][fname1]
			Files[uid1][dir1][fname1] = nil
			local abspath1 = mpath.join_be(dir1, fname1)
			local abspath2 = mpath.join_be(dir2, fname2)
			local s = backend.read_file(uid1, abspath1)
			backend.write_file(uid2, abspath2, s)
			backend.remove_file(uid1, abspath1)
			return true
		end
	end
end

-- check if file is visible for CPU
function pdp13.file_exists(pos, path)
	--print("file_exists")
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		if mounted and Files[uid] and Files[uid][dir] then
			return Files[uid][dir][fname] ~= nil
		end
	end
end

function pdp13.file_size(pos, path)
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		if mounted and Files[uid] and Files[uid][dir] then
			return tonumber(Files[uid][dir][fname]) or 0
		end
	end
	return 0
end

function pdp13.read_file(pos, path)
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		if mounted and Files[uid] and Files[uid][dir] and Files[uid][dir][fname] then
			local abspath = mpath.join_be(dir, fname)
			return backend.read_file(uid, abspath)
		end
	end
end

function pdp13.write_file(pos, path, s)
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	if drive then
		local uid = get_uid(pos, drive)
		local mounted = drive == 'h' or M(pos):get_int("mounted_t") == 1
		if mounted and Files[uid] then
			Files[uid][dir] = Files[uid][dir] or {}
			local abspath = mpath.join_be(dir, fname)
			if backend.write_file(uid, abspath, s) then
				Files[uid][dir][fname] = string.len(s)
				return true
			end
		end
	end
end

function pdp13.make_dir(pos, dir)
	local mem = techage.get_nvm(pos)
	if mem.curr_drive  == "h" and mem.curr_dir == "" then
		local uid = get_uid(pos, mem.curr_drive)
		if Files[uid] and not Files[uid][dir] then
			Files[uid][dir] = Files[uid][dir] or {}
			local s = "_dir_"
			local fname = "@@"
			local abspath = mpath.join_be(dir, fname)
			if backend.write_file(uid, abspath, s) then
				Files[uid][dir][fname] = string.len(s)
				return true
			end
		end
	end
end

function pdp13.remove_dir(pos, dir)
	local mem = techage.get_nvm(pos)
	if mem.curr_drive  == "h" and mem.curr_dir == "" then
		local uid = get_uid(pos, mem.curr_drive)
		if Files[uid] and Files[uid][dir] and not next(Files[uid][dir]) then
			if dir ~= "" then
				Files[uid][dir] = nil
			end
			return true
		end
	end
end

function pdp13.change_drive(pos, drive)
	local mem = techage.get_nvm(pos)
	if drive == "t" or drive == "h" then
		mem.curr_drive = drive
		mem.curr_dir = ""
		return true
	end
end

function pdp13.change_dir(pos, dir)
	--print("change_dir")
	local mem = techage.get_nvm(pos)
	if mpath.is_dir(dir) and mem.curr_drive == "h" then
		local uid = get_uid(pos, mem.curr_drive)
		if Files[uid] and Files[uid][dir] then
			mem.curr_dir = dir
			return true
		end
	elseif dir == ".." then
		mem.curr_dir = ""
		return true
	elseif dir == "t" or dir == "h" then
		mem.curr_drive = dir
		mem.curr_dir = ""
		return true
	end
end

function pdp13.make_file_visible(pos, path)
	--print("make_file_visible")
	local mem = techage.get_nvm(pos)
	local drive, dir, fname = mpath.splitpath(mem, path)
	if drive then
		local uid = get_uid(pos, drive)
		local abspath = mpath.join_be(dir, fname)
		local size = backend.file_size(uid, abspath)
		if size > 0 then
			Files[uid] = Files[uid] or {}
			Files[uid][dir] = Files[uid][dir] or {}
			Files[uid][dir][fname] = size
			return true
		end
	end
end

function pdp13.init_filesystem(pos, has_tape, has_hdd)
	--print("init_filesystem", has_tape, has_hdd)
	if has_tape then
		local uid = get_uid(pos, "t")
		Files[uid] = Files[uid] or {}
		Files[uid][""] = Files[uid][""] or {}
		backend.write_file(uid, "pipe.sys", uid)
	end
	if has_hdd then
		local uid = get_uid(pos, "h")
		Files[uid] = Files[uid] or {}
		Files[uid][""] = Files[uid][""] or {}
		backend.write_file(uid, "pipe.sys", uid)
	end
end

function pdp13.mount_drive(pos, drive, mount)
	--print("mount_drive")
	if drive == "t" then
		M(pos):set_int("mounted_t", mount == true and 1 or 0)
	end
end
	
function pdp13.set_boot_path(pos, path)
	local mem = techage.get_nvm(pos)
	local drive, dir, _ = mpath.splitpath(mem, path)
	--print("set_boot_path", path, drive, dir)
	if dir ~= "" then
		mem.boot_path = drive .. "/" .. dir .. "/"
	else
		mem.boot_path = drive .. "/"
	end
	--print("set_boot_path2", mem.boot_path)
end	

function pdp13.get_boot_path(pos, path)
	local mem = techage.get_nvm(pos)
	if mpath.is_filename(path) then
		-- return standard boot path
		--print("get_boot_path1", (mem.boot_path or "t/") .. path)
		return (mem.boot_path or "t/") .. path
	end
	-- return the given path
	--print("get_boot_path2", path)
	return path  
end	
