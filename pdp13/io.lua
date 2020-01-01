--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 I/O

]]--


-- for lazy programmers
local M = minetest.get_meta
local get_tbl = function(pos,key)      return minetest.deserialize(M(pos):get_string(key)) or {} end
local set_tbl = function(pos,key,tbl)  M(pos):set_string(key, minetest.serialize(tbl)) end

local TTY_INP_CNTR = 0x003E
local TTY_OUT_CNTR = 0x003F
local TTY_INP_BUFF = 0x0040
local TTY_OUT_BUFF = 0x0080
local TTY_BUF_SIZE = 64
local IO_OUTP = 0
local IO_STS  = 1
local IO_INP  = 2

local ActionHandlers = {}
local SystemHandlers = {}

local function io_hash(number, io_num, io_type)
	return ((tonumber(number) or 0) * 256) + (io_num * 8) + (io_type)
end

-- Action (input/output):
--   u16_resp = output(pos, u3_offs, u16_data) -- return 0/1
--   u16_resp = input(pos, u3_offs)
local function register_action(own_num, io_num, io_type, io_pos, credit, func)
	print("ActionHandlers: io_num, io_type, credit", io_num, io_type, credit)
	local hash = io_hash(own_num, io_num, io_type)
	ActionHandlers[hash] = ActionHandlers[hash] or {}
	ActionHandlers[hash] = {pos = io_pos, func = func, credit = credit}
end

function pdp13.update_action_list(pos)
	local own_num = M(pos):get_string("node_number")
	print("update_action_list")
	local addr_tbl = get_tbl(pos, "addr_tbl")
	for io_num, number in pairs(addr_tbl) do
		print("io_num, number", io_num, number)
		local info = techage.get_node_info(number)
		if info then
			local resp = techage.send_single(0, number, "pdp13_input")
			if resp then
				register_action(own_num, io_num-1, vm16.IN, info.pos, resp.credit, resp.func)
			end
			resp = techage.send_single(0, number, "pdp13_output")
			if resp then
				register_action(own_num, io_num-1, vm16.OUT, info.pos, resp.credit, resp.func)
			end
		elseif number ~= "" then
			print("pdp13.update_action_list: invalid node number", number)
		end
	end
end

-- regA, regB, points = func(vm, pos, addr, regA, regB)
function pdp13.register_system_handler(addr, regA, func)
	SystemHandlers[addr] = SystemHandlers[addr] or {}
	SystemHandlers[addr][regA] = func
end
	
function pdp13.vm_input(vm, pos, addr)
	local own_num = M(pos):get_string("node_number")
	local io_num = math.floor(addr / 8)
	local offs = (addr % 8)
	local hash = io_hash(own_num, io_num, vm16.IN)
	local item = ActionHandlers[hash]
	if item then
		return item.func(item.pos, offs), item.credit
	end
	return 0xFFFF, 100
end	

function pdp13.vm_output(vm, pos, addr, value)
	local own_num = M(pos):get_string("node_number")
	local io_num = math.floor(addr / 8)
	local offs = (addr % 8)
	local hash = io_hash(own_num, io_num, vm16.OUT)
	local item = ActionHandlers[hash]
	if item then
		return item.func(item.pos, offs, value), item.credit
	end
	return 0xFFFF, 100
end	

function pdp13.vm_system(vm, pos, addr, regA, regB)
	if SystemHandlers[addr] and SystemHandlers[addr][regA] then
		return SystemHandlers[addr][regA](vm, pos, addr, regA, regB)
	end
	return 0xFFFF, regB, 100
end

-- read from TTY (addr=0, regA=0, regB=unused)
local function read_tty(vm, pos, addr, regA, regB)
	local sts,_ = pdp13.vm_input(vm, pos, IO_STS)
	local offs = TTY_INP_BUFF
	while sts ~= 0 and offs < (TTY_INP_BUFF + TTY_BUF_SIZE) do
		local data,_ = pdp13.vm_input(vm, pos, IO_INP)
		print("vm16.poke", offs, data)
		vm16.poke(vm, offs, data)
		sts,_ = pdp13.vm_input(vm, pos, IO_STS)
		offs = offs + 1
	end
	vm16.poke(vm, TTY_INP_CNTR, offs - TTY_BUF_SIZE)
	print("vm_system", offs, 100)
	return offs - TTY_BUF_SIZE, regB, 100
end

-- write to TTY
local function write_tty(vm, pos, addr, regA, regB)
	local num = math.min(vm16.peek(vm, TTY_OUT_CNTR), TTY_BUF_SIZE) or 0
	print("write_tty", addr, regA, regB, num)
	if num > 0 then
		local tbl = vm16.read_mem(vm, TTY_OUT_BUFF, num)
		print("write_tty2", num, dump(tbl))
		local sts,_ = pdp13.vm_output(vm, pos, regB, tbl)
		vm16.poke(vm, TTY_OUT_CNTR, 0)
		return sts, regB, 100
	end
	return 0xffff, regB, 100
end

pdp13.register_system_handler(0, 0, read_tty)
pdp13.register_system_handler(0, 1, write_tty)

