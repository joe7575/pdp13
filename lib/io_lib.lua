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
	print("OutputNumbers", own_num, addr, rmt_num)
	OutputNumbers[own_num] = OutputNumbers[own_num] or {}
	OutputNumbers[own_num][addr]= rmt_num
	InputAdresses[own_num] = InputAdresses[own_num] or {}
	InputAdresses[own_num][rmt_num] = addr
end

function pdp13.register_AddressType(own_num, addr, type_)
	print("AddressTypes", own_num, addr, type_)
	AddressTypes[own_num] = AddressTypes[own_num] or {}
	AddressTypes[own_num][addr]= type_
end

function pdp13.register_CommandTopic(type_, cmnd, topic)
	print("CommandTopics",type_, cmnd, topic)
	CommandTopics[type_] = CommandTopics[type_] or {}
	CommandTopics[type_][cmnd] = topic
end

function pdp13.register_ResponseTopic(type_, cmnd, topic)
	print("ResponseTopics",type_, cmnd, topic)
	ResponseTopics[type_] = ResponseTopics[type_] or {}
	ResponseTopics[type_][cmnd] = topic
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
	print("on_cmnd_input", own_num, addr, value)
end

--
-- CPU/VM16 event handlers
--
local function on_output(pos, addr, data)
	local own_num = M(pos):get_string("node_number")
	local num = (OutputNumbers[own_num] or {})[addr]
    local type_ = (AddressTypes[own_num] or {})[addr] or "techage"
    local topic = (CommandTopics[type_] or {})[data]

	Inputs[own_num] = Inputs[own_num] or {}
    if num and topic then
        Outputs[own_num][addr] = topic
		-- TODO: allow other mods for communication
        local resp = techage.send_single(own_num, num, topic)
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
end

local function on_input(pos, addr)
	local own_num = M(pos):get_string("node_number")
	return (Inputs[own_num] or {})[addr] or 0xFFFF
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
