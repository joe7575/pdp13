--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam 4 (to get the Hard Disk tape)

]]--

-- for lazy programmers
local M = minetest.get_meta

local function collatz(n)
	local tbl = {}
	while n ~= 1 do
		table.insert(tbl, n)
		if n % 2 == 0 then
			n = n / 2
		else
			n = 3 * n + 1
		end
	end
	table.insert(tbl, n)
	return tbl
end


local function exam_provide_number(pos, address, val1, val2)
	local val = math.floor(math.random() * 255) + 11
	--local val = val1

	local mem = pdp13.get_nvm(pos)
	mem.exam4_res = collatz(val)
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
	
	local num = #mem.exam4_res
	local result = vm16.read_mem(pos, val1, num)
	
	for i = 1, num do
		if mem.exam4_res[i] ~= result[i] then
			pdp13.send_terminal_command(pos, mem, "println", "Expected value on index " .. i .. " is " .. mem.exam4_res[i])
			pdp13.send_terminal_command(pos, mem, "println", "and not " .. result[i])
			return 0
		end
	end
	pdp13.send_terminal_command(pos, mem, "println", "Congratulations!")
	add_tape(pos, owner, "pdp13:tape_hdd")
	return 1
end

local help = [[+-----+----------------+-------------+------+
|sys #| Exam4          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $306  request number    -      -     number
 $307  provide array    @result -     1=ok]]

pdp13.register_SystemHandler(0x0306, exam_provide_number, help)
pdp13.register_SystemHandler(0x0307, exam_check_result)

