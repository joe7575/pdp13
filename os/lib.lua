--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Standard Library

]]--

local function string_to_number(pos, address, val1, val2)
	local s = vm16.read_ascii(pos, val1, 5)
	local val = tonumber(s)
	if val then
		return val
	end
	return 65535
end

local function number_to_string(pos, address, val1, val2)
	local s = tostring(val1)
	vm16.write_ascii(pos, val2, s.."\000")
	return 1
end

--          |sys # | O/S            |   A    B   | rtn  |
local s1 = " $18   string to num    addr    -    number"
local s2 = " $19   num to string    number addr  1=ok"
pdp13.register_SystemHandler(0x18, string_to_number, s1)
pdp13.register_SystemHandler(0x19, number_to_string, s2)
--pdp13.register_SystemHandler(0x0301, number_to_string, s2)
