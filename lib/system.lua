--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 SYS Command Registration

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local SystemHandlers = {}  -- on startup generated: t[address] = func

pdp13.SysDesc = ""

function pdp13.register_SystemHandler(address, func, desc)
	SystemHandlers[address] = func
	if desc then
		desc = desc:gsub(",", "\\,")
		desc = desc:gsub("\n", ",")
		desc = desc:gsub("#", "\\#")
		desc = desc:gsub(";", "\\;")
		pdp13.SysDesc = pdp13.SysDesc..","..desc
	end
end

function pdp13.on_system(pos, address, val1, val2)
	if SystemHandlers[address] then
		local sts, resp = pcall(SystemHandlers[address], pos, address, val1, val2)
		if sts then
			return resp
		else
			minetest.log("warning", "[PDP13] pcall exception: "..resp)
		end
	end
	return 0xFFFF
end

-- For fake calls from Lua
-- if val is a string, addr is the VM address for the string in val
function pdp13.sys_call(pos, address, val1, val2, addr1, addr2)
	if val1 then
		if type(val1) == "string" and addr1 then
			vm16.write_ascii(pos, addr1, val1)
			val1 = addr1
		end
	end
	if val2 then
		if type(val2) == "string" and addr2 then
			vm16.write_ascii(pos, addr2, val2)
			val2 = addr2
		end
	end
	return pdp13.on_system(pos, address, val1, val2)
end
