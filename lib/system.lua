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

local function on_system(pos, address, val1, val2)
	return SystemHandlers[address] and SystemHandlers[address](pos, address, val1, val2) or 0xFFFF
end

-- Overwrite one of the five event handlers
vm16.register_callbacks(nil, nil, on_system)

-- For fake calls from Lua
-- if val is a string, addr is the VM address for the string in val
function pdp13.sys_call(pos, address, val1, val2, addr1, addr2)
	if val1 then
		if type(val1) == "string" and addr1 then
			vm16.write_ascii(pos, addr1, val1.."\000")
			val1 = addr1
		end
	end
	if val2 then
		if type(val2) == "string" and addr2 then
			vm16.write_ascii(pos, addr2, val2.."\000")
			val2 = addr2
		end
	end
	if SystemHandlers[address] then
		return SystemHandlers[address](pos, address, val1, val2)
	end
	return 65535
end
