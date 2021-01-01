 --[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Helper functions

]]--

function pdp13.max_num_files(drive)
	if drive == "h" then
		return 512
	else
		return 64
	end
end
	
function pdp13.max_fs_size(drive)
	if drive == "h" then
		return 500  -- kByte
	else
		return 60  -- kByte
	end
end

function pdp13.range(val, min, max, default)
	val = tonumber(val) or default
	val = math.max(val, min)
	val = math.min(val, max)
	return val
end

function pdp13.gen_filepattern(s)
	if s ==  "" then
		s = "*"
	end
	s = string.gsub(s, "%.", "%%.")
	s = string.gsub(s, "*", "%.%.%-")
	return "^"..s.."$"
end

function pdp13.fmatch(s, pattern)
	return string.find(s, pattern) ~= nil
end


-- "h/myfile" or "t/myfile" or "myfile"
function pdp13.filename(s, defaultdrive)
	local drive = s:byte(1)
	local slash = s:byte(2)
	
	if slash == 47 and (drive == 116 or drive == 104) then  -- '/' 't' 'h'
		drive = string.char(drive)
		s = s:sub(3)
	else
		drive = defaultdrive or "t"
	end
	if string.find(s, "^[%w_][%w_][%w_%.]+$") then
		return drive, s
	end
end

-- "h/myfile" or "t/myfile"
function pdp13.filespattern(s, defaultdrive)
	local drive = s:byte(1)
	local slash = s:byte(2)
	
	if slash == 47 and (drive == 116 or drive == 104) then  -- '/' 't' 'h'
		drive = string.char(drive)
		s = s:sub(3)
	else
		drive = defaultdrive or "t"
	end
	if string.find(s, "^[%w_%.%*]+$") then
		return drive, s
	end
end

function pdp13.is_h16_file(s)
	return string.find(s, "%.h16") ~= nil
end

function pdp13.is_com_file(s)
	return string.find(s, "%.com") ~= nil
end

function pdp13.kbyte(val)
	if val > 9999 then
		return tostring(math.floor(val / 1024) + 1).."K"
	else
		return tostring(val)
	end
end
