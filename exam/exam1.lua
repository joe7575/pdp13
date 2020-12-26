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

local function exam1_provide_positions(pos, address, val1, val2)
	local x1 = math.floor(math.random() * 1000)
	local y1 = math.floor(math.random() * 1000)
	local z1 = math.floor(math.random() * 1000)
	local x2 = math.floor(math.random() * 1000)
	local y2 = math.floor(math.random() * 1000)
	local z2 = math.floor(math.random() * 1000)

	local mem = techage.get_nvm(pos)
	mem.exam1_dist = math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1) + 1

	vm16.poke(pos, val1 + 0, x1)
	vm16.poke(pos, val1 + 1, y1)
	vm16.poke(pos, val1 + 2, z1)
	vm16.poke(pos, val1 + 3, x2)
	vm16.poke(pos, val1 + 4, y2)
	vm16.poke(pos, val1 + 5, z2)
	return 1
end

local function exam1_check_result(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")
	
	minetest.chat_send_player(owner, "[PDP13] Exam1 result: "..mem.exam1_dist.. " expected, "..val1.. " received")
	if mem.exam1_dist == val1 then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		pdp13.operator_cmnd(pos, "punch", "pdp13:tapemonitor")
	end
	return mem.exam1_dist == val1 and 1 or 0
end

local s1 = [[+-----+----------------+-------------+------+
|sys #| Exam1          | A    | B    | rtn  |
 $300  request pos1/2   addr    -     1=ok]]

local s2 = " $301  provide dist     result  -     1=ok"
pdp13.register_SystemHandler(0x0300, exam1_provide_positions, s1)
pdp13.register_SystemHandler(0x0301, exam1_check_result, s2)

