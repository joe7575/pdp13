--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 4 (to get the COMM tape)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function exam_provide_number(pos, address, val1, val2)
	local val = math.floor(math.random() * 65535)

	local mem = pdp13.get_nvm(pos)
	mem.exam4_res = tostring(val)
	mem.exam4_time = minetest.get_gametime()
	
	return val
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
	
	mem.exam4_res = mem.exam4_res or 0
	mem.exam4_time = mem.exam4_time or 0

	if mem.exam4_time + 1 < minetest.get_gametime() then
		minetest.chat_send_player(owner, "[PDP13] Timeout reached!")
		return 0
	end
	
	local s = vm16.read_ascii(pos, val1, 6)
	pdp13.send_terminal_command(pos, mem, "println", 
        '"' .. mem.exam4_res .. '" expected, "' .. s .. '" received')
	if mem.exam4_res == s then
		pdp13.send_terminal_command(pos, mem, "println", "Congratulations!")
		add_tape(pos, owner, "pdp13:tape_comm")
		return 1
	end
	return 0
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam4          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $306  request number    -      -     number
 $307  provide string   @result -     1=ok]]

pdp13.register_SystemHandler(0x0306, exam_provide_number, help)
pdp13.register_SystemHandler(0x0307, exam_check_result)


