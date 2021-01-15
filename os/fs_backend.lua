--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 File System backend for real file access

]]--

local WP = minetest.get_worldpath() .. "/pdp13/"  -- to store the files

local backend = {}

-- path is always the path with filename, but without drive (which is the uid)
function backend.file_size(uid, path)
	local f = io.open(WP..uid.."_"..path, "rb")
	if f then
		local size = f:seek("end")
		f:close()
		return size
	end
	return 0
end

function backend.file_exists(uid, path)
	return backend.file_size(uid, path) > 0
end
	
-- Return a table with all files: {uid ,path, size}
function backend.scan_file_system()
	-- For the case it doesn't exist
	minetest.mkdir(WP)
	
	local tbl = {}
	for _,name in ipairs(minetest.get_dir_list(WP)) do
		local t = string.split(name, "_", false, 1)
		if #t == 2 then
			local uid, path = t[1], t[2]
			table.insert(tbl, {uid = uid, path = path, size = backend.file_size(uid, path)})
		end
	end
	return tbl
end

function backend.read_file(uid, path)
	local f = io.open(WP..uid.."_"..path, "rb")
	if f then
		local s = f:read("*all")
		f:close()
		return s
	end
end
	
function backend.write_file(uid, path, s)
	path = WP..uid.."_"..path
	-- Consider unit test, where safe_file_write is not available
	if not pcall(minetest.safe_file_write, path, s) then
		local f = io.open(path, "wb")
		if f then
			f:write(s)
			f:close()
			return true
		end
		return false
	end
	return true
end

function backend.remove_file(uid, path)
	os.remove(WP..uid.."_"..path)
end

return backend