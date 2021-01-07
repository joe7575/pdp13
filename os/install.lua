--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 J/OS install helper/cheating functions
	
]]--

local MP = minetest.get_modpath("pdp13")

local Tape1Files = {
	"boot",
	"shell1.h16",
	"shell2.com",
	"cat.com",
	"h16com.h16",
	"pipe.sys",
	"help.txt",
}

local Tape2Files = {
	"asm.com",
	"cmdstr.asm",
	"less.asm",
	"nextstr.asm",
	"strcat.asm",
	"strcmp.asm",
	"strcpy.asm",
	"strlen.asm",
	"strrstr.asm",
	"strsplit.asm",
	"strstrip.asm",
}

local Tape3Files = {
	"asm.asm",
	"cat.asm",
	"h16com.asm",
	"hellow.asm",
	"shell1.asm",
	"shell2.asm",
	"",
}

local function copy_file(pos, fname)
	local src_file = MP.."/system/"..fname
	local dst_file = pdp13.real_file_path(pos, fname)..fname
	-- read file
	local f = io.open(src_file, "rb")
	if f then
		local s = f:read("*all")
		f:close()
		-- write file
		f = io.open(dst_file, "wb")
		if f then
			f:write(s)
			f:close()
		end
	end
end

function pdp13.tape_detected(pos, s)
	if s == "pdp13:tape_system1" then
		for _,fname in ipairs(Tape1Files) do
			copy_file(pos, fname)
			pdp13.make_file_visible(pos, "t/"..fname)
		end
	elseif s == "pdp13:tape_system2" then
		for _,fname in ipairs(Tape2Files) do
			copy_file(pos, fname)
			pdp13.make_file_visible(pos, "t/"..fname)
		end
	elseif s == "pdp13:tape_system3" then
		for _,fname in ipairs(Tape3Files) do
			copy_file(pos, fname)
			pdp13.make_file_visible(pos, "t/"..fname)
		end
	end
end
