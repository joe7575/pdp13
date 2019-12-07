--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Task States

]]--

-- for lazy programmers
local P2P = minetest.string_to_pos
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local M = minetest.get_meta

local RAM_SIZE    = 12  -- 2^12 = 4096 words RAM

local VMList = {}


function pdp13.vm_create(owner, pos, vm)
	print("vm_create")
	local hash = minetest.hash_node_position(pos)
	VMList[owner] = VMList[owner] or {}
	VMList[owner][hash] = vm
end	

function pdp13.vm_get(owner, pos)
	print("vm_get")
	local hash = minetest.hash_node_position(pos)
	if not VMList[owner] or not VMList[owner][hash] then
		VMList[owner] = VMList[owner] or {}
		VMList[owner][hash] = pdp13lib.create(RAM_SIZE)
		print("->created")
	end
	return VMList[owner][hash]
end	

function pdp13.vm_destroy(owner, pos)
	print("vm_destroy")
	local hash = minetest.hash_node_position(pos)
	if VMList[owner] and VMList[owner][hash] then
		VMList[owner][hash] = nil
	end
	M(pos):set_string("vm", "")
end	
	
function pdp13.vm_store(owner, pos)
	print("vm_store")
	local hash = minetest.hash_node_position(pos)
	if VMList[owner] and VMList[owner][hash] then
		local s = pdp13lib.get_vm(VMList[owner][hash])
		M(pos):set_string("vm", s)
		M(pos):mark_as_private("vm")
	end
end

function pdp13.vm_restore(owner, pos)
	print("vm_restore")
	local s = M(pos):get_string("vm")
	if s ~= "" then
		local vm = pdp13lib.create(RAM_SIZE)
		if vm then
			pdp13lib.set_vm(vm, s)
			pdp13.vm_create(owner, pos, vm)
		end
	end
end

function pdp13.vm_resume(owner, pos)
	print("vm_resume")
	local vm = pdp13.vm_get(owner, pos)
	if pos and vm then
		pdp13.add_to_scheduler(pos, vm)
	end
end
	
function pdp13.vm_suspend(owner, pos)
	print("vm_suspend")
	local vm = pdp13.vm_get(owner, pos)
	if pos and vm then
		pdp13.remove_from_scheduler(pos, vm)
	end
end
	