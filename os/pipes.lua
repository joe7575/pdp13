--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Pipe for text line exchange

]]--

-- for lazy programmers
local M = minetest.get_meta

local MAX_PIPE_LEN = pdp13.MAX_PIPE_LEN  -- lines of text

local Pipes = {}


function pdp13.init_pipe(pos)
	local number = tonumber(M(pos):get_string("node_number"))
	Pipes[number] = {fifo = {}, first = 0, last = -1}
end

function pdp13.delete_pipe(pos)
	local number = tonumber(M(pos):get_string("node_number"))
	Pipes[number] = nil
end

function pdp13.pipe_size(pos)
	local number = tonumber(M(pos):get_string("node_number"))
	Pipes[number] = Pipes[number] or {fifo = {}, first = 0, last = -1}
	return Pipes[number].last - Pipes[number].first + 1
end

function pdp13.push_pipe(pos, items)
	local number = tonumber(M(pos):get_string("node_number"))
	Pipes[number] = Pipes[number] or {fifo = {}, first = 0, last = -1}
	local pipe = Pipes[number]
	local size = pipe.last - pipe.first + 1
	local num = math.min(MAX_PIPE_LEN - size, #items)
	--print("push_pipe", number, size, num)
	for i = 1, num do
		pipe.fifo[pipe.last + i] = items[i]
	end
	pipe.last = pipe.last + num
	return num
end

function pdp13.pop_pipe(pos, num)
	local number = tonumber(M(pos):get_string("node_number"))
	local pipe = Pipes[number] or {fifo = {}, first = 0, last = -1}
	local size = pipe.last - pipe.first + 1
	--print("pop_pipe", number, size, num)
	num = math.min(size, num)
	local items = {}
	for i = pipe.first, pipe.first + num - 1 do
		table.insert(items, pipe.fifo[i])
		pipe.fifo[i] = nil -- to allow garbage collection
	end
	pipe.first = pipe.first + num
	return items
end

function pdp13.file_to_pipe(pos, path)
	local fname = path.."pipe.sys"
	local s = pdp13.read_file(pos, fname)
	pdp13.remove_files(pos, fname)
	if s then
		local items = pdp13.text2table(s)
		return pdp13.push_pipe(pos, items)
	end
	return 0
end

local function push_pipe(cpu_pos, address, val1)
	local s = vm16.read_ascii(cpu_pos, val1, pdp13.MAX_LINE_LEN)
	return pdp13.push_pipe(cpu_pos, {s})
end

local function pop_pipe(cpu_pos, address, val1)
	local items = pdp13.pop_pipe(cpu_pos, 1)
	if next(items) then
		vm16.write_ascii(cpu_pos, val1, items[1])
		return 1
	end
	return 0
end

local function pipe_size(cpu_pos, address, val1)
	return pdp13.pipe_size(cpu_pos)
end

local function flush_pipe(cpu_pos, address, val1)
	return pdp13.delete_pipe(cpu_pos)
end

local help = [[+-----+----------------+-------------+------+
|sys #| Pipes          | A    | B    | rtn  |
+-----+----------------+-------------+------+
 $80   push pipe        @text   -     1=ok
 $81   pop pipe         @dest   -     1=ok
 $82   pipe size         -      -     size
 $83   flush pipe        -      -     1=ok]]

pdp13.register_SystemHandler(0x80, push_pipe, help)
pdp13.register_SystemHandler(0x81, pop_pipe)
pdp13.register_SystemHandler(0x82, pipe_size)
pdp13.register_SystemHandler(0x83, flush_pipe)

vm16.register_sys_cycles(0x80, 500)
vm16.register_sys_cycles(0x81, 500)
vm16.register_sys_cycles(0x82, 200)
vm16.register_sys_cycles(0x83, 500)

