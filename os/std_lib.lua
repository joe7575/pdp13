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

local function string_length(pos, address, val1, val2)
	local s = vm16.read_ascii(pos, val1, pdp13.MAX_LINE_LEN)
	return string.len(s)
end

local function string_concat(pos, address, val1, val2)
	local s1 = vm16.read_ascii(pos, val1, pdp13.MAX_LINE_LEN)
	local s2 = vm16.read_ascii(pos, val2, pdp13.MAX_LINE_LEN)
	vm16.write_ascii(pos, val1, s1..s2.."\000")
	return val1
end

local help = [[+-----+----------------+-------------+------+
|sys #| stdlib         | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $20   string to num    @str    -     number
 $21   num to string    number @dest  1=ok
 $22   string length    @str    -     nchar
 $23   string concat    @dest  @str   @dest]]
 
pdp13.register_SystemHandler(0x20, string_to_number)
pdp13.register_SystemHandler(0x21, number_to_string)
pdp13.register_SystemHandler(0x22, string_length)
pdp13.register_SystemHandler(0x23, string_concat)
