--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 2 (to get the BIOS ROM)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function exam_provide_positions(pos, address, val1, val2)
	local x1 = math.floor(math.random() * 1000)
	local y1 = math.floor(math.random() * 1000)
	local z1 = math.floor(math.random() * 1000)
	local x2 = math.floor(math.random() * 1000)
	local y2 = math.floor(math.random() * 1000)
	local z2 = math.floor(math.random() * 1000)

	local mem = techage.get_nvm(pos)
	mem.exam2_res = math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1) + 1
	mem.exam2_time = minetest.get_gametime()

	vm16.poke(pos, val1 + 0, x1)
	vm16.poke(pos, val1 + 1, y1)
	vm16.poke(pos, val1 + 2, z1)
	vm16.poke(pos, val1 + 3, x2)
	vm16.poke(pos, val1 + 4, y2)
	vm16.poke(pos, val1 + 5, z2)
	return 1
end

local function exam_check_result(pos, address, val1, val2)
	local mem = techage.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")

	mem.exam2_res = mem.exam2_res or 0
	mem.exam2_time = mem.exam2_time or 0

	if mem.exam2_time + 1 < minetest.get_gametime() then
		minetest.chat_send_player(owner, "[PDP13] Timeout reached!")
		return 0
	end
	
	minetest.chat_send_player(owner,
        "[PDP13] Exam2 result: "..mem.exam2_res.. " expected, "..val1.. " received")
	if mem.exam2_res == val1 then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		pdp13.operator_cmnd(pos, "punch", "pdp13:tape_bios")
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam2          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $302  request pos1/2   @pos    -     1=ok
 $303  provide dist     @result -     1=ok]]

pdp13.register_SystemHandler(0x0302, exam_provide_positions, help)
pdp13.register_SystemHandler(0x0303, exam_check_result)
