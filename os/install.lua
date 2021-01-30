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
	"pipe.sys",
	"help.txt",
	"ptrd.com",
	"ptwr.com",
	"h16com.h16",
	"asm.com",
}

local Tape2Files = {
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
	"cpyfiles.asm",
	"ptrd.asm",
	"ptwr.asm",
}


local function copy_file(pos, fname)
	local src_file = MP.."/system/" .. fname
	local dst_file = "t/" .. fname
	-- read file
	local f = io.open(src_file, "rb")
	if f then
		local s = f:read("*all")
		f:close()
		-- write file
                pdp13.write_file(pos, dst_file, s)
	end
end

function pdp13.tape_detected(pos, s)
	if s == "pdp13:tape_system1" then
		for _,fname in ipairs(Tape1Files) do
			copy_file(pos, fname)
		end
	elseif s == "pdp13:tape_system2" then
		for _,fname in ipairs(Tape2Files) do
			copy_file(pos, fname)
		end
	elseif s == "pdp13:tape_system3" then
		for _,fname in ipairs(Tape3Files) do
			copy_file(pos, fname)
		end
	end
end
