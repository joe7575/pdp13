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


local CYCLE_TIME = 0.1      -- CPU call frequency
local NUM_INSTR  = 4547     -- num of instructions per cycle

local call_cpu = pdp13.call_cpu
local JobQueue = {}
local first = 0
local last = -1
local LocalTime = 0
local LoadAverage = 0
local RunningCPUs = 0

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
	local t = minetest.get_us_time()
	LocalTime = LocalTime + dtime
	local item = pop()
	RunningCPUs = 0
	while item do
		if item.pos and item.vm then
			call_cpu(item.pos, item.vm, NUM_INSTR)
			push(item)
			RunningCPUs = RunningCPUs + 1
		end
		item = pop()
	end
	t = minetest.get_us_time() - t
	LoadAverage = ((LoadAverage * 100) + t) / 101  -- low pass filter
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


local function status_report()
	local load = string.format("%f ppm", LoadAverage * 10)
	minetest.log("action", "[pdp13] CPUs running="..RunningCPUs..", CPU load="..load)
	minetest.after(600, status_report)
end

minetest.after(600, status_report)