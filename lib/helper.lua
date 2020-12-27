 --[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Helper functions

]]--

local tDrives = {
	[116] = 1,  -- t(ape)
	[104] = 2,  -- h(ard disk)
}

local DriveChar = {116, 104}

local CurrentDrive = {}

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


-- "h/myfile" or "t/myfile" or "myfile"
function pdp13.filename(s, number)
	local drive
	
	if s:byte(2) == 47 then  -- '/'
		drive = tDrives[s:byte(1)]
		s = s:sub(3)
	else
		drive = CurrentDrive[number] or 1
	end
	if drive and string.find(s, "^[%w_][%w_][%w_%.]+$") then
		CurrentDrive[number] = drive
		return drive, s
	end
end

-- "h/myfile" or "t/myfile"
function pdp13.filespattern(s, number)
	local drive
	
	if s:byte(2) == 47 then  -- '/'
		drive = tDrives[s:byte(1)]
		s = s:sub(3)
	else
		drive = CurrentDrive[number] or 1
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
		return 32
	else
		return 256
	end
end
	
function pdp13.max_fs_size(drive)
	if drive == 1 then
		return 50  -- kByte
	else
		return 400  -- kByte
	end
end

function pdp13.kbyte(val)
	if val > 0 then
		return math.floor(val / 1024) + 1
	end
	return 0
end

function pdp13.set_current_drive(number, drive)
	if type(drive) == "string" then
		drive = tDrives[drive] or 1
	end
	CurrentDrive[number] = drive
end

function pdp13.get_current_drive(number)
	return CurrentDrive[number] or 1
end

function pdp13.get_current_drive_char(number)
	return DriveChar[CurrentDrive[number] or 1] or 116 -- t
end
