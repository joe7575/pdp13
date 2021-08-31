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
local ADDRESS_TYPE = "techage"

if minetest.global_exists("tubelib") then
	ADDRESS_TYPE = "tubelib"
end
	
--
-- Register function
--
function pdp13.register_OutputNumber(own_num, addr, rmt_num)
	OutputNumbers[own_num] = OutputNumbers[own_num] or {}
	OutputNumbers[own_num][addr] = rmt_num
	InputAdresses[own_num] = InputAdresses[own_num] or {}
	InputAdresses[own_num][rmt_num] = addr
end

function pdp13.register_AddressType(own_num, addr, type_)
	AddressTypes[own_num] = AddressTypes[own_num] or {}
	AddressTypes[own_num][addr] = type_
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
		
	if val1 >= 128 then 
		Outputs[own_num][addr] = val2
	else
		Outputs[own_num][addr] = val1
	end
	
	local num = (OutputNumbers[own_num] or {})[addr]
	local type_ = (AddressTypes[own_num] or {})[addr] or ADDRESS_TYPE
	local topic = (CommandTopics[type_] or {})[val1]

	if num and topic then
		-- TODO: allow other mods for communication
		local resp = pdp13.send_single(own_num, num, topic, val2)
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
	number = tonumber(number) or 0
	OutputNumbers[number] = get_tbl(pos, "OutputNumbers")
	InputAdresses[number] = get_tbl(pos, "InputAdresses")
	AddressTypes[number]  = get_tbl(pos, "AddressTypes")
end

function pdp13.io_store(pos, number)
	number = tonumber(number) or 0
	set_tbl(pos, "OutputNumbers", OutputNumbers[number])
	set_tbl(pos, "InputAdresses", InputAdresses[number])
	set_tbl(pos, "AddressTypes", AddressTypes[number])
end

function pdp13.reset_output_buffer(cpu_num)
	cpu_num = tonumber(cpu_num) or 0
	--print("reset_output_buffer", cpu_num)
	Outputs[cpu_num] = nil
end

function pdp13.get_input(cpu_num, addr)
	cpu_num = tonumber(cpu_num) or 0
	--print("get_input", cpu_num, addr)
	return (Inputs[cpu_num] or {})[addr]
end

function pdp13.get_output(cpu_num, addr)
	cpu_num = tonumber(cpu_num) or 0
	--print("get_output", cpu_num, addr)
	return (Outputs[cpu_num] or {})[addr]
end

function pdp13.get_rmt_node_number(cpu_num, addr)
	return OutputNumbers[cpu_num] and OutputNumbers[cpu_num][addr]
end

function pdp13.after_place_node(pos, placer, name, descr)
	local meta = M(pos)
	local own_num = pdp13.add_node(pos, name)
	meta:set_string("node_number", own_num)  -- for techage
	meta:set_string("own_number", own_num)  -- for tubelib
	meta:set_string("owner", placer:get_player_name())
	meta:set_string("infotext", descr.." -")
end

function pdp13.infotext(meta, descr, text)
	local own_num = meta:get_string("node_number") or ""
	local numbers = meta:get_string("numbers") or ""
	if numbers ~= "" then
		meta:set_string("infotext", descr.." "..own_num..": "..S("connected with").." "..numbers)
	elseif text then
		meta:set_string("infotext", descr.." "..own_num..": "..text)
	else
		meta:set_string("infotext", descr.." "..own_num)
	end
end
