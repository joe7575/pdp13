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

local function exam_provide_positions(pos, address, val1, val2)
	local x1 = math.floor(math.random() * 1000)
	local y1 = math.floor(math.random() * 1000)
	local z1 = math.floor(math.random() * 1000)
	local x2 = math.floor(math.random() * 1000)
	local y2 = math.floor(math.random() * 1000)
	local z2 = math.floor(math.random() * 1000)

	local mem = pdp13.get_nvm(pos)
	mem.exam3_res = math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1) + 1
	mem.exam3_time = minetest.get_gametime()

	vm16.poke(pos, val1 + 0, x1)
	vm16.poke(pos, val1 + 1, y1)
	vm16.poke(pos, val1 + 2, z1)
	vm16.poke(pos, val1 + 3, x2)
	vm16.poke(pos, val1 + 4, y2)
	vm16.poke(pos, val1 + 5, z2)
	return 1
end

local function add_tape(pos, owner, tape)
	local names = {"pdp13:tape_chest"}
	local resp = pdp13.send(pos, nil, names, "add_tape", tape)
	if not resp then
		minetest.chat_send_player(owner, "Tape Chest missing or not enough space!")
	end
end

local function exam_check_result(pos, address, val1, val2)
	local mem = pdp13.get_nvm(pos)
	local meta = M(pos)
	local owner = meta:get_string("owner")

	mem.exam3_res = mem.exam3_res or 0
	mem.exam3_time = mem.exam3_time or 0

	if mem.exam3_time + 1 < minetest.get_gametime() then
		minetest.chat_send_player(owner, "[PDP13] Timeout reached!")
		return 0
	end
	
	minetest.chat_send_player(owner,
        "[PDP13] Exam3 result: "..mem.exam3_res.. " expected, "..val1.. " received")
	if mem.exam3_res == val1 then
		minetest.chat_send_player(owner, "***### !!! Congratulations !!! ###***")
		add_tape(pos, owner, "pdp13:tape_install")
		add_tape(pos, owner, "pdp13:tape_system1")
		add_tape(pos, owner, "pdp13:tape_system2")
		add_tape(pos, owner, "pdp13:tape_system3")
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam3          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $304  request pos1/2   @pos    -     1=ok
 $305  provide dist     @result -     1=ok]]

pdp13.register_SystemHandler(0x0304, exam_provide_positions, help)
pdp13.register_SystemHandler(0x0305, exam_check_result)
