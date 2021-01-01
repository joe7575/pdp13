--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 3 (to get the OS install tape)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function exam_provide_number(pos, address, val1, val2)
	local val = math.floor(math.random() * 65535)

	local mem = techage.get_nvm(pos)
	mem.exam3_res = tostring(val)
	return val
end

local function exam_check_result(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")
	
	local s = vm16.read_ascii(pos, val1, 6)
	minetest.chat_send_player(owner,
        "[PDP13] Exam3 result: '"..mem.exam3_res.. "' expected, '"..s.. "' received")
	if mem.exam3_res == s then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		pdp13.operator_cmnd(pos, "punch", "pdp13:tape_install")
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam3          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $304  request number    -      -     number
 $305  provide string   @result -     1=ok]]

pdp13.register_SystemHandler(0x0304, exam_provide_number, help)
pdp13.register_SystemHandler(0x0305, exam_check_result)

