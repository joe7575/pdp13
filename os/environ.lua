--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Environmental functions

]]--

-- for lazy programmers
local M = minetest.get_meta

local function get_timeofday(pos, address, val1, val2)
	local t = minetest.get_timeofday()
	return math.floor(t * 1440)
end

local function get_day_count(pos, address, val1, val2)
	return minetest.get_day_count()
end

local help = [[+-----+----------------+-------------+------+
|sys #| Environment    | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $90   get timeofday     -      -     minutes
 $91   get day count     -      -     days]]

pdp13.register_SystemHandler(0x90, get_timeofday, help)
pdp13.register_SystemHandler(0x91, get_day_count)

