--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 User Datagram Protocol "stack" for inter CPU communication

]]--

-- for lazy programmers
local M = minetest.get_meta

local DataStorage = pdp13.UdpData
local MSG_SIZE = 64


-- val1 = mem address for src_data
-- val2 = I/O port => remote node number
local function upd_send(pos, address, val1, val2)
	if M(pos):get_int("rom_size") >= 2 then  -- OS enabled
		local own_num = M(pos):get_string("node_number")
		own_num = tonumber(own_num)
		local rmt_num = pdp13.get_rmt_node_number(own_num, val2)
		if rmt_num then
			DataStorage[rmt_num] = DataStorage[rmt_num] or {}
			DataStorage[rmt_num][own_num] = vm16.read_mem(pos, val1, MSG_SIZE)
			return 1
		end
	end
	return 65535
end

-- val1 = mem address for dst_data
-- val2 = I/O port => remote node number
local function upd_receive(pos, address, val1, val2)
	if M(pos):get_int("rom_size") >= 2 then  -- OS enabled
		local own_num = M(pos):get_string("node_number")
		own_num = tonumber(own_num)
		local rmt_num = pdp13.get_rmt_node_number(own_num, val2)
		if rmt_num then
			local msg = DataStorage[own_num] and DataStorage[own_num][rmt_num]
			if msg then
				vm16.write_mem(pos, val1, msg)
				DataStorage[own_num][rmt_num] = nil
				return 1
			end
			return 0
		end
	end
	return 65535
end

local help = [[+-----+----------------+-------------+------+
|sys #| Communication  | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $40   send datagram    @data  port   1=ok
 $41   recv datagram    @dest  port   1=ok]]

pdp13.register_SystemHandler(40, upd_send, help)
pdp13.register_SystemHandler(41, upd_receive)
