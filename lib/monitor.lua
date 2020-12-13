--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Monitor program

]]--

local Commands = {}  -- [cmnd] = func(pos, mem, cmd, rest): returns list of output strings

local function hex_dump(tbl)
	local t2 = {}
	for _,val in ipairs(tbl) do
		t2[#t2+1] = string.format("%04X", val)
	end
	return table.concat(t2, " ")
end

local function mem_dump(pos, addr, mem)
	local lines = {}
	for i = 1, (#mem/4) do
		local offs = (i - 1) * 4
		lines[i] = string.format("%04X: %04X %04X %04X %04X", 
				addr+offs, mem[1+offs], mem[2+offs], mem[3+offs], mem[4+offs])
	end
	return lines
end

local function convert_to_numbers(s)
	local tbl = {}
	for _,val in ipairs(string.split(s, " ")) do
		tbl[#tbl+1] = pdp13.string_to_number(val)
	end
	return tbl
end

Commands["?"] = function(pos, mem, cmd, rest)
	mem.mstate = nil
	return {
		"?         help",
		"st        start",
		"sp        stop",
		"re        reset",
		"nx        next step",
		"ad #      set address" 
		"dm #      dump memory",
		"sm #      set memory",
		"as #      assemble",
		"di #      disassemble",
		"ct # txt  copy text to mem",
		"cm # # #  copy mem from to num",
	}
end

-- start
Commands["st"] = function(pos, mem, cmd, rest)
	
	
-- assemble
Commands["as"] = function(pos, mem, cmd, rest)
	if cmd == "as" then
		mem.mstate = "as"
		mem.maddr = pdp13.string_to_number(rest)
		return {string.format("%04X: ", mem.maddr)}
	else
		local tbl = pdp13.assemble(rest)
		if tbl then
			vm16.write_mem(pos, mem.maddr, tbl)
			local addr = mem.maddr
			mem.maddr = mem.maddr + #tbl
			return {string.format("%04X: %-15s %s\n", addr, hex_dump(tbl), rest)}
		else
			return {rest.." <-- syntax error!"}
		end
	end
end

-- dump memory
Commands["dm"] = function(pos, mem, cmd, rest)
	if cmd == "dm" then
		mem.mstate = "dm"
		mem.maddr = pdp13.string_to_number(rest)
	else
		mem.maddr = mem.maddr or 0
	end
	local dump = vm16.read_mem(pos, mem.maddr, 32)
	local addr = mem.maddr
	mem.maddr = mem.maddr + 32
	if dump then
		return mem_dump(pos, addr, dump)
	end
	return {"Address error"}
end

-- set memory
Commands["sm"] = function(pos, mem, cmd, rest)
	if cmd == "sm" then
		mem.mstate = "sm"
		mem.maddr = pdp13.string_to_number(rest)
		return {string.format("%04X: ", mem.maddr)}
	else
		local tbl = convert_to_numbers(rest)
		local addr = mem.maddr
		mem.maddr = mem.maddr + #tbl
		vm16.write_mem(pos, addr, tbl)
		return {string.format("%04X: %s", addr, hex_dump(tbl))}
	end
end
	
Commands["go"] = function(pos, mem, cmd, rest)	
	mem.mstate = nil
	mem.maddr = pdp13.string_to_number(rest)
	vm16lib.set_pc(pos, mem.maddr)
	return {"running"}
end

	
--local function disassemble(vm, pos, s)
--	local _,mem = pdp13.get_mem(pos)
--	address(mem, s)
--	local tbl = vm16.read_mem(vm, mem.mon_addr, 4)
--	local num, cmnd = pdp13.disassemble(tbl)
--	tbl = vm16.read_mem(vm, mem.mon_addr, num)
--	write_tty(vm, pos, string.format("%04X: %-15s %s", mem.mon_addr, pdp13.hex_dump(tbl), cmnd))
--	mem.mon_addr = mem.mon_addr + num
--	sleep(1)
--end

function pdp13.monitor(cpu_pos, mem, command)
	local words = string.split(command, " ", false, 1)
	if Commands[words[1]] then
		return Commands[words[1]](cpu_pos, mem, words[1], words[2])
	elseif mem.mstate and Commands[mem.mstate] then
		return Commands[mem.mstate](cpu_pos, mem, "", command)
	else
		return Commands["?"](cpu_pos, mem, words[1], words[2])
	end
end
