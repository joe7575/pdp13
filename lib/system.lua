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
