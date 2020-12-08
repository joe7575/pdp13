--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Common I/O library

]]--

-- for lazy programmers
local M = minetest.get_meta
local get_tbl = function(pos,key)      return minetest.deserialize(M(pos):get_string(key)) or {} end
local set_tbl = function(pos,key,tbl)  M(pos):set_string(key, minetest.serialize(tbl)) end

local OutputNumbers = {}  -- node metadata: t[own_num][addr] = rmt_num
local InputAdresses = {}  -- node metadata: t[own_num][rmt_num] = addr
local AddressTypes  = {}  -- node metadata: t[own_num][addr] = type_
local CommandTopics  = {}  -- on startup generated: t[type_][cmnd] = topic
local ResponseTopics = {}  -- on startup generated: t[type_][resp] = topic
local Inputs  = {}  -- volatile: t[own_num][addr] = value
local Outputs = {}  -- volatile: t[own_num][addr] = value

--
-- Register function
--
function pdp13.register_OutputNumber(own_num, addr, rmt_num)
	OutputNumbers[own_num] = OutputNumbers[own_num] or {}
	OutputNumbers[own_num][addr]= rmt_num
	InputAdresses[own_num] = InputAdresses[own_num] or {}
	InputAdresses[own_num][rmt_num] = addr
end

function pdp13.register_AddressType(own_num, addr, type_)
	AddressTypes[own_num] = AddressTypes[own_num] or {}
	AddressTypes[own_num][addr]= type_
end

function pdp13.register_CommandTopic(type_, topic_str, cmnd)
	CommandTopics[type_] = CommandTopics[type_] or {}
	CommandTopics[type_][cmnd] = topic_str
end

function pdp13.register_ResponseTopic(type_, topic_str, cmnd)
	ResponseTopics[type_] = ResponseTopics[type_] or {}
	ResponseTopics[type_][topic_str] = cmnd
end

--
-- Inputs/Commands (on/off) from other nodes
--
function pdp13.on_cmnd_input(own_num, src_num, value)
	own_num, src_num = tonumber(own_num), tonumber(src_num)
	local addr = (InputAdresses[own_num] or {})[src_num]
	if addr then
		Inputs[own_num] = Inputs[own_num] or {}
		Inputs[own_num][addr] = value
	end
	--print("on_cmnd_input", own_num, addr, value)
end

--
-- CPU/VM16 event handlers
--
local function on_output(pos, addr, val1, val2)
	local own_num = M(pos):get_string("node_number")
	own_num = tonumber(own_num) or 0
	Outputs[own_num] = Outputs[own_num] or {}
	Inputs[own_num] = Inputs[own_num] or {}
		
	print("on_output1", own_num, addr, val1, val2)
	
	-- value changed?
	if Outputs[own_num][addr] ~= (val2 or val1) then 
		local num = (OutputNumbers[own_num] or {})[addr]
		local type_ = (AddressTypes[own_num] or {})[addr] or "techage"
		local topic = (CommandTopics[type_] or {})[val1]
	
		print("on_output2", num, type_, topic)
		if num and topic then
			Outputs[own_num][addr] = val2 or val1
			-- TODO: allow other mods for communication
			local resp = techage.send_single(own_num, num, topic, val2)
			if resp then
				Inputs[own_num][addr] = ((ResponseTopics[type_] or {})[resp])
			else
				Inputs[own_num][addr] = 0xFFFF  -- receiver does not respond
			end
		elseif not num then
			Inputs[own_num][addr] = 0xFFFE -- invalid addr
		else
			Inputs[own_num][addr] = 0xFFFD -- invalid data
		end
		return true  -- output changed
	end
	return false  -- output not changed
end

local function on_input(pos, addr)
	local own_num = M(pos):get_string("node_number")
	own_num = tonumber(own_num) or 0
	return (Inputs[own_num] or {})[addr] or 0xFFFF -- nothing reveived or invalid addr
end

-- Overwrite two of the five event handlers
vm16.register_callbacks(on_input, on_output)

--
-- API functions
--
function pdp13.io_restore(pos, number)
	print("io_restore")
	number = tonumber(number)
	OutputNumbers[number] = get_tbl(pos, "OutputNumbers")
	InputAdresses[number] = get_tbl(pos, "InputAdresses")
	AddressTypes[number]  = get_tbl(pos, "AddressTypes")
end

function pdp13.io_store(pos, number)
	print("io_store")
	number = tonumber(number)
	set_tbl(pos, "OutputNumbers", OutputNumbers[number])
	set_tbl(pos, "InputAdresses", InputAdresses[number])
	set_tbl(pos, "AddressTypes", AddressTypes[number])
end

function pdp13.get_input(cpu_num, addr)
	print("get_input", cpu_num, addr)
	return (Inputs[cpu_num] or {})[addr]
end

function pdp13.get_output(cpu_num, addr)
	print("get_output", cpu_num, addr)
	return (Outputs[cpu_num] or {})[addr]
end
