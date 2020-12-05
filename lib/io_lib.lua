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


-- key = node_number * 256 + I/O-addr
local OutputNumbers = {}  -- node metadata: t[key] = node_number
local InputAdresses = {}  -- node metadata: [own_num][dest_num] = addr
local AddressTypes  = {}  -- node metadata: t[key] = type_
local CommandTopics  = {}  -- startup generated: t[type_][cmnd] = topic
local ResponseTopics = {}  -- startup generated: t[type_][resp] = topic
local Inputs  = {}  -- volatile: t[key] = value
local Outputs = {}  -- volatile: t[key] = value

-- Translate the combination of two numbers to a key into the Inputs table
local function numbers_to_key(own_num, src_num)
	local addr = (InputAdresses[own_num] or {})[src_num]
	if addr then
		return own_num * 256 + addr
	end
end

--
-- Register function
--
function pdp13.register_OutputNumber(own_num, addr, dest_num)
	local key = own_num * 256 + addr
	OutputNumbers[key]= dest_num
	InputAdresses[own_num][dest_num] = addr
end

function pdp13.register_AddressType(own_num, addr, type_)
	local key = own_num * 256 + addr
	AddressTypes[key]= type_
end

function pdp13.register_CommandTopic(type_, cmnd, topic)
	CommandTopics[type_] = CommandTopics[type_] or {}
	CommandTopics[type_][cmnd] = topic
end

function pdp13.register_ResponseTopic(type_, cmnd, topic)
	ResponseTopics[type_] = ResponseTopics[type_] or {}
	ResponseTopics[type_][cmnd] = topic
end

--
-- Inputs/Commands (on/off) from other nodes
--
function pdp13.on_cmnd_input(pos, src_num, value)
	local own_num = M(pos):get_string("node_number")
    local key = numbers_to_key(own_num, src_num)
	if key then
		Inputs[key] = value
	end
end

--
-- CPU/VM16 event handlers
--
local function on_output(pos, addr, data)
	local own_num = M(pos):get_string("node_number")
    local key = own_num * 256 + addr
	local num = OutputNumbers[key]
    local type_ = AddressTypes[key] or "techage"
    local topic = CommandTopics[type_][data]

    if num and topic then
        Outputs[key] = topic
		-- TODO: allow other mods for communication
        local resp = techage.send_single(own_num, num, topic)
        if resp then
            Inputs[key] = ResponseTopics[type_][resp]
        else
            Inputs[key] = 0xFFFF
        end
    else
        Inputs[key] = 0xFFFF
    end
end

local function on_input(pos, addr)
	local own_num = M(pos):get_string("node_number")
    local key = own_num * 256 + addr
	return Inputs[key] or 0xFFFF
end

-- Overwrite two of the five event handlers
vm16.register_callbacks(on_input, on_output)

--
-- API functions
--
function pdp13.io_restore(pos)
	OutputNumbers = get_tbl(pos, "OutputNumbers")
	InputAdresses = get_tbl(pos, "InputAdresses")
	AddressTypes  = get_tbl(pos, "AddressTypes")
end

function pdp13.io_store(pos)
	set_tbl(pos, "OutputNumbers", OutputNumbers)
	set_tbl(pos, "InputAdresses", InputAdresses)
	set_tbl(pos, "AddressTypes", AddressTypes)
end

	