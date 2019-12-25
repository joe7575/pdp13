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

local VMList = {}

function pdp13.cpu_running(pos)
	local mem = tubelib2.get_mem(pos)
	return mem.started
end

function pdp13.vm_create(owner, pos, tExtensions)
	print("vm_create", owner)
	print(dump(tExtensions))
	local ram_size = 1 + #tExtensions
	local hash = minetest.hash_node_position(pos)
	local vm = vm16.create(pos, ram_size)
	for idx,item in ipairs(tExtensions) do
		if item.type == "rom" then
			vm16.mark_rom_bank(vm, idx)
			vm16.write_mem(vm, item.addr, item.code)
		end
	end
	vm16.init_mem_banks(vm)
	VMList[owner] = VMList[owner] or {}
	VMList[owner][hash] = vm
end	

function pdp13.vm_get(owner, pos)
	print("vm_get")
	local hash = minetest.hash_node_position(pos)
	if not VMList[owner] or not VMList[owner][hash] then
--		VMList[owner] = VMList[owner] or {}
--		VMList[owner][hash] = pdp13.vm_restore(owner, pos)
		print("#################### Das hätte nicht passieren dürfen !!!")
		return
	end
	return VMList[owner][hash]
end	

function pdp13.vm_destroy(owner, pos)
	print("vm_destroy")
	local hash = minetest.hash_node_position(pos)
	if VMList[owner] and VMList[owner][hash] then
		vm16.destroy(VMList[owner][hash], pos)
		VMList[owner][hash] = nil
	end
end	
	
function pdp13.vm_store(owner, pos)
	print("vm_store")
	local hash = minetest.hash_node_position(pos)
	if VMList[owner] and VMList[owner][hash] then
		vm16.vm_store(VMList[owner][hash], pos)
	end
end

function pdp13.vm_restore(owner, pos)
	print("vm_restore")
	local vm = vm16.vm_restore(pos)
	if vm then
		local hash = minetest.hash_node_position(pos)
		VMList[owner] = VMList[owner] or {}
		VMList[owner][hash] = vm
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
	