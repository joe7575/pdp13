--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	SYS #0 (TTY) routines

]]--


-- for lazy programmers
local M = minetest.get_meta
local get_tbl = function(pos,key)      return minetest.deserialize(M(pos):get_string(key)) or {} end
local set_tbl = function(pos,key,tbl)  M(pos):set_string(key, minetest.serialize(tbl)) end

 local function to_dec_string(vm, pos, addr, regA, regB)
	local num = math.min(vm16.peek(vm, 0x003f), 64) 
	local s = string.format("%u", regB)
	for i = 1,string.len(s) do
		vm16.poke(vm, 0x0080 + num, string.byte(i))
		num = num + 1
	end
	vm16.poke(vm, 0x0080 + num, string.byte(i))
	
	local offs = 0
	while sts ~= 0 and offs < 64 do
		local data,_ = vm_input(vm, pos, 1)
		print("write_mem", offs, data)
		vm16.write_mem(vm, offs, {data})
		sts,_ = vm_input(vm, pos, 0)
		offs = offs + 1
	end
	print("vm_system", offs, 100)
	return offs, regB, points
end

pdp13.register_system_handler(0, 0, system0)

