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

local help = [[+-----+----------------+-------------+------+
|sys #| stdlib         | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $20   string to num    @str    -     number
 $21   num to string    number @dest  1=ok]]
 
pdp13.register_SystemHandler(0x20, string_to_number, help)
pdp13.register_SystemHandler(0x21, number_to_string)
--pdp13.register_SystemHandler(0x22, number_to_string, s2)
