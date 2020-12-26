 --[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Helper functions

]]--

function pdp13.range(val, min, max, default)
	val = tonumber(val) or default
	val = math.max(val, min)
	val = math.min(val, max)
	return val
end

function pdp13.gen_filepattern(s)
	s = string.gsub(s, "%.", "%%.")
	s = string.gsub(s, "*", "%.%.%-")
	return "^"..s.."$"
end

function pdp13.fmatch(s, pattern)
	return string.find(s, pattern) ~= nil
end

local tDrives = {
	[116] = 1,  -- t(ape)
	[104] = 2,  -- h(ard disk)
}

-- "h/myfile" or "t/myfile" or "myfile"
function pdp13.filename(s, default_drive_num)
	local drive
	
	if s:byte(2) == 47 then  -- '/'
		drive = tDrives[s:byte(1)]
		s = s:sub(3)
	else
		drive = default_drive_num or 1
	end
	if drive and string.find(s, "^[%w_][%w_][%w_%.]+$") then
		return drive, s
	end
end

-- "h/myfile" or "t/myfile"
function pdp13.filespattern(s, default_drive_num)
	local drive
	
	if s:byte(2) == 47 then  -- '/'
		drive = tDrives[s:byte(1)]
		s = s:sub(3)
	else
		drive = default_drive_num or 1
	end
	if drive and string.find(s, "^[%w_%.%*]+$") then
		return drive, s
	end
end

function pdp13.is_h16_file(s)
	return string.find(s, "%.h16") ~= nil
end

function pdp13.max_num_files(drive)
	if drive == 1 then
		return 8
	else
		return 64
	end
end
	
function pdp13.max_fs_size(drive)
	if drive == 1 then
		return 25  -- kByte
	else
		return 200  -- kByte
	end
end

function pdp13.kbyte(val)
	if val > 0 then
		return math.floor(val / 1024) + 1
	end
	return 0
end
