--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Scheduler

]]--

-- for lazy programmers
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local M = minetest.get_meta


local CYCLE_TIME = 2 --0.2 -- CPU call frequency

local call_cpu = pdp13.call_cpu
local JobQueue = {}
local first = 0
local last = -1
local LocalTime = 0

local function push(item)
	last = last + 1
	item.time = LocalTime + CYCLE_TIME
	JobQueue[last] = item
end

local function pop()
	if first > last then return end
	local item = JobQueue[first]
	if item.time <= LocalTime then
		JobQueue[first] = nil -- to allow garbage collection
		first = first + 1
		return item
	end
end

-- Scheduler
minetest.register_globalstep(function(dtime)
	LocalTime = LocalTime + dtime
	local item = pop()
	while item do
		print("Scheduler", next(JobQueue))
		if item.pos and item.vm then
			print("call", P2S(item.pos))
			call_cpu(item.pos, item.vm)
			push(item)
		end
		item = pop()
	end
end)

function pdp13.add_to_scheduler(pos, vm)
	print("add_to_scheduler")
	-- not available after startup
	call_cpu = pdp13.call_cpu
	push({pos = pos, vm = vm})
end

function pdp13.remove_from_scheduler(pos, vm)
	print("remove_from_scheduler")
	for idx, item in pairs(JobQueue) do
		if item.pos and pos and vector.equals(item.pos, pos) then
			item.vm = nil
		end
	end
end
