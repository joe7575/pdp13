--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Tools as SYS commands

]]--
local IE = ...

-- for lazy programmers
local M = minetest.get_meta

local function filesize(fname)
	local f = io.open(fname, "rb")
	if f then
		local size = f:seek("end")
		f:close()
		return size
	end
	return 0
end

local function read_file(fname)
	local f = io.open(fname, "rb")
	if f then
		local s = f:read("*all")
		f:close()
		return s
	end
end

local function assembler(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.MAX_LINE_LEN)
	local param = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)
	print("assembler", fname, param)
	
	if fname and param then
		local path = pdp13.real_file_path(pos, fname)
		if path then
			IE.os.execute("vm16asm --srv "..path.." "..fname.." "..param)
			if param:find("c") then 
				fname = string.split(fname, ".", 1)[1]..".com"
				pdp13.make_file_visible(pos, fname) 
			else
				fname = string.split(fname, ".", 1)[1]..".h16"
				pdp13.make_file_visible(pos, fname) 
			end
			if param:find("l") then 
				fname = string.split(fname, ".", 1)[1]..".lst"
				pdp13.make_file_visible(pos, fname) 
			end
			return pdp13.file_to_pipe(pos, path)
		end
	end
	return 0
end

pdp13.register_SystemHandler(0x200, assembler)

