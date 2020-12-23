--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 2 (to get the OS ROM)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function exam2_provide_positions(pos, address, val1, val2)
	local val = math.floor(math.random() * 65535)

	local mem = techage.get_nvm(pos)
	mem.exam2_res = tostring(val)
	return val
end

local function exam2_check_result(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")
	
	local s = vm16.read_ascii(pos, val1, 6)
	minetest.chat_send_player(owner, "[PDP13] Exam2 result: '"..mem.exam2_res.. "' expected, '"..s.. "' received")
	if mem.exam2_res == s then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		pdp13.operator_cmnd(pos, "punch", "pdp13:tapeos")
	end
	return mem.exam2_res == s and 1 or 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam2          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $302  request number    -      -     number
 $303  provide string   addr    -     1=ok]]

pdp13.register_SystemHandler(0x0302, exam2_provide_positions, help)
pdp13.register_SystemHandler(0x0303, exam2_check_result)

