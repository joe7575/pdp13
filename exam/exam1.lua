--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 1 (to get the Monitor ROM)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function exam_provide_numbers(pos, address, val1, val2)
	local value = math.floor(math.random() * 400)

	local mem = pdp13.get_nvm(pos)
	mem.exam1_res = math.floor((value * 9) / 5) + 32
	mem.exam1_time = minetest.get_gametime()

	return value
end

local function exam_check_result(pos, address, val1, val2)
	local mem = pdp13.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")
	
	local res = val1
	mem.exam1_res = mem.exam1_res or 0
	mem.exam1_time = mem.exam1_time or 0

	if mem.exam1_time + 1 < minetest.get_gametime() then
		minetest.chat_send_player(owner, "[PDP13] Timeout reached!")
		return 0
	end
		
	minetest.chat_send_player(owner, 
	"[PDP13] Exam1 result: "..mem.exam1_res.. " expected, "..res.. " received")
	if mem.exam1_res == res then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		pdp13.operator_cmnd(pos, "punch", "pdp13:tape_monitor")
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam1          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $300  request number    -      -     value
 $301  provide result   result  -     1=ok]]

pdp13.register_SystemHandler(0x0300, exam_provide_numbers, help)
pdp13.register_SystemHandler(0x0301, exam_check_result)

