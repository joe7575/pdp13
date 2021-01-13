 --[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 File system path functions

]]--

local path = {}
local ptrn_drive = "^[th]$"
local ptrn_dir   = "^%w%w%w?$"
local ptrn_fname = "^[%w_][%w_%.]+$"
local ptrn_fptrn = "^[%w_%.%*]+$"
local MAX_DIR_LEN   = 3
local MAX_FNAME_LEN = 12  -- 8 + '.' + 3
--                   t   /   bin           /   file.ext                 
local MAX_PATH_LEN = 1 + 1 + MAX_DIR_LEN + 1 + MAX_FNAME_LEN

path.MAX_FNAME_LEN = MAX_FNAME_LEN
path.MAX_DIR_LEN   = MAX_DIR_LEN
path.MAX_PATH_LEN  = MAX_PATH_LEN

-- translate from "*.*" to Lua pattern
function path.gen_filepattern(s)
	if s ==  "" then
		s = "*"
	end
	s = string.gsub(s, "%.", "%%.")
	s = string.gsub(s, "*", "%.%.%-")
	return "^"..s.."$"
end

-- Return true if filename matches the given file pattern
function path.filename_match(filename, pattern)
	return string.find(filename, ptrn_fname) and string.find(filename, pattern) ~= nil
end

-- Split given string and return the parts as drive, dir, and filename
function path.splitpath(mem, s)
	local words = {}
    for w in s:gmatch("[^/]+") do
		table.insert(words, w)
    end
	local w1, w2, w3, w4 = unpack(words,1,4)
	mem.curr_drive = mem.curr_drive or "t"
	mem.curr_dir = mem.curr_dir or ""
	
	if not w2 then
		if string.find(w1, ptrn_fptrn) and string.len(w1) <= MAX_FNAME_LEN then
			return mem.curr_drive, mem.curr_dir, w1
		end
	elseif not w3 then
		if string.find(w2, ptrn_fptrn) and string.len(w2) <= MAX_FNAME_LEN  then
			if string.find(w1, ptrn_drive) then
				return w1, mem.curr_dir, w2
			end
			if string.find(w1, ptrn_dir) then
				return mem.curr_drive, w1, w2
			end
		end
	elseif not w4 then
		if string.find(w1, ptrn_drive) then
			if string.find(w2, ptrn_dir) then
				if string.find(w3, ptrn_fptrn) and string.len(w3) <= MAX_FNAME_LEN then
					return w1, w2, w3
				end
			end
		end
	end
end

function path.splitext(s)
	local _, _, base, ext = string.find(s, "(.+)%.(.*)")
	base = base or s
	ext = ext or ""
	return base, ext
end

-- Return path with [<dir>$]<filename> for backend
function path.join_be(dir, fname)
	if dir ~= "" then
		return dir .. "$" .. fname
	else
		return fname
	end
end

-- Return path with [<dir>/]<filename> for frontend
function path.join_fe(dir, fname)
	if dir ~= "" then
		return dir .. "/" .. fname
	else
		return fname
	end
end

-- ext is a string like "com" or "asm"
function path.has_ext(s, ext)
	local _, pos = string.find(s, "%."..ext)
	return pos == string.len(s)
end

function path.is_filename(s)
	return string.find(s, ptrn_fname) and string.len(s) <= MAX_FNAME_LEN
end

function path.is_dir(s)
	return string.find(s, ptrn_dir) ~= nil
end

return path