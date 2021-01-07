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
	local n1lw = math.floor(math.random() * 3000)
	local n1hw = math.floor(math.random() * 3000)
	local n2lw = math.floor(math.random() * 3000)
	local n2hw = math.floor(math.random() * 3000)

	local mem = techage.get_nvm(pos)
	mem.exam1_res = (n1lw + (n1hw * 0x10000)) + (n2lw + (n2hw * 0x10000))
	mem.exam1_time = minetest.get_gametime()

	vm16.poke(pos, val1 + 0, n1lw)
	vm16.poke(pos, val1 + 1, n1hw)
	vm16.poke(pos, val1 + 2, n2lw)
	vm16.poke(pos, val1 + 3, n2hw)
	return 1
end

local function exam_check_result(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")
	
	local reslw = vm16.peek(pos, val1 + 0)
	local reshw = vm16.peek(pos, val1 + 1)
	local res = reslw + (reshw * 0x10000)
	
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
 $300  request numbers  @num    -     1=ok
 $301  provide sum      @result -     1=ok]]

pdp13.register_SystemHandler(0x0300, exam_provide_numbers, help)
pdp13.register_SystemHandler(0x0301, exam_check_result)

