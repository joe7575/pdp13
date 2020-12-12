--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 SYS commands

]]--

-- for lazy programmers
local M = minetest.get_meta

local SystemHandlers = {}  -- on startup generated: t[address] = func

function pdp13.register_SystemHandler(address, func)
	SystemHandlers[address] = func
end

local function on_system(pos, address, val1, val2)
	return SystemHandlers[address] and SystemHandlers[address](pos, address, val1, val2) or 0xFFFF
end

-- Overwrite one of the five event handlers
vm16.register_callbacks(nil, nil, on_system)

local function send_cmnd(pos, dst_num, topic, payload)
	local own_num = M(pos):get_string("node_number")
	return techage.send_single(own_num, dst_num, topic, payload)
end

local function telewriter_output(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = vm16.read_ascii(pos, val1, 80)
	return send_cmnd(pos, number, "output", s)
end

local function telewriter_input_string(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	if s and vm16.write_ascii(pos, val1, s) then
		print("telewriter_input_string", val1, s)
		return #s
	end
	return 65535
end

local function telewriter_input_number(pos, address, val1, val2)
	local number = M(pos):get_string("telewriter_number")
	local s = send_cmnd(pos, number, "input")
	print("telewriter_input_number", s, tonumber(s) or 65535)
	return tonumber(s) or 65535
end


pdp13.SysDesc = [[---------------------------------
sys #0   ; telewriter text output
]]

pdp13.SysDesc = pdp13.SysDesc:gsub(",", "\\,")
pdp13.SysDesc = pdp13.SysDesc:gsub("\n", ",")
pdp13.SysDesc = pdp13.SysDesc:gsub("#", "\\#")
pdp13.SysDesc = pdp13.SysDesc:gsub(";", "\\;")


pdp13.register_SystemHandler(0, telewriter_output)
pdp13.register_SystemHandler(1, telewriter_input_string)
pdp13.register_SystemHandler(2, telewriter_input_number)

