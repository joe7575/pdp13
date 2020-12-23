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
	for _,val in ipairs(tbl or {}) do
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

-- st(art)  s(to)p  r(ese)t  n(ext)  r(egister)  ad(dress)  d(ump)  en(ter)
Commands["?"] = function(pos, mem, cmd, rest)
	mem.mstate = nil
	return {
		"?         help",
		"st        start",
		"sp        stop",
		"rt        reset",
		"n         next step",
		"r         register",
		"ad #      set address",
		"d  #      dump memory",
		"en #      enter data",
		"as #      assemble",
		"di #      disassemble",
		"ct # txt  copy text to mem",
		"cm # # #  copy mem from to num",
		"ex        exit monitor",
	}
end

-- start
Commands["st"] = function(pos, mem, cmd, rest)
	pdp13.start_cpu(pos)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	return {"running"}
end

-- stop
Commands["sp"] = function(pos, mem, cmd, rest)
	pdp13.stop_cpu(pos)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	local cpu = vm16.get_cpu_reg(pos)
	local num, s = pdp13.disassemble(cpu)
	return {s}
end

-- reset
Commands["rt"] = function(pos, mem, cmd, rest)
	vm16.set_pc(pos, 0) 
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	local cpu = vm16.get_cpu_reg(pos)
	local num, s = pdp13.disassemble(cpu)
	return {s}
end

-- next step
Commands["n"] = function(pos, mem, cmd, rest)
	pdp13.single_step_cpu(pos)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	local cpu = vm16.get_cpu_reg(pos)
	local num, s = pdp13.disassemble(cpu)
	return {s}
end
	
-- register
Commands["r"] = function(pos, mem, cmd, rest)
	local cpu = vm16.get_cpu_reg(pos)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	return {
		string.format("A:%04X B:%04X C:%04X D:%04X", cpu.A, cpu.B, cpu.C, cpu.D),
		string.format("X:%04X Y:%04X P:%04X S:%04X", cpu.X, cpu.Y, cpu.PC, cpu.SP),
	}
end

-- set address
Commands["ad"] = function(pos, mem, cmd, rest)
	local addr = pdp13.string_to_number(rest)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	vm16.set_pc(pos, addr) 
	local cpu = vm16.get_cpu_reg(pos)
	local num, s = pdp13.disassemble(cpu)
	return {s}
end
	
-- dump memory
Commands["d"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
	if cmd == "d" then
		mem.mstate = "d"
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

-- enter data
Commands["en"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
	if cmd == "en" then
		mem.mstate = "en"
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
		
-- assemble
Commands["as"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
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
			return {string.format("%04X: %-11s %s", addr, hex_dump(tbl), rest)}
		else
			return {rest.." <-- syntax error!"}
		end
	end
end

-- disassemble
Commands["di"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
	if cmd == "di" then
		mem.mstate = "di"
		mem.maddr = pdp13.string_to_number(rest)
	else
		mem.maddr = mem.maddr or 0
	end
	local dump = vm16.read_mem(pos, mem.maddr, 16)
	local tbl = {}
	local offs = 1
	for i = 1, 8 do
		local cpu = {PC = mem.maddr + offs - 1, mem0 = dump[offs], mem1 = dump[offs+1]}
		local num, s = pdp13.disassemble(cpu)
		offs = offs + num
		tbl[#tbl+1] = s
	end
	mem.maddr = mem.maddr + offs - 1
	return tbl
end

-- copy text
Commands["ct"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	local words = string.split(rest, " ", true, 1)
	if #words == 2 then
		local addr = pdp13.string_to_number(words[1])
		vm16.write_ascii(pos, addr, words[2].."\000")
		return {"text copied"}
	end
	return {"error!"}
end

-- copy memory
Commands["cm"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = true
	mem.mstate = nil
	local words = string.split(rest, " ", false, 2)
	if #words == 3 then
		local src_addr = pdp13.string_to_number(words[1])
		local dst_addr = pdp13.string_to_number(words[2])
		local number = pdp13.string_to_number(words[3])
		if src_addr and dst_addr and number then
			local tbl = vm16.read_mem(pos, src_addr, number)
			vm16.write_mem(pos, dst_addr, tbl)
			return {"memory copied"}
		end
	end
	return {"error!"}
end

-- exit monitor
Commands["ex"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = false
	pdp13.exit_monitor(pos)
	return {"finished."}
end


function pdp13.monitor(cpu_pos, mem, command)
	if cpu_pos and mem and command then
		local words = string.split(command, " ", false, 1)
		if Commands[words[1]] then
			return Commands[words[1]](cpu_pos, mem, words[1], words[2])
		elseif mem.mstate and Commands[mem.mstate] then
			return Commands[mem.mstate](cpu_pos, mem, "", command)
		else
			return Commands["?"](cpu_pos, mem, words[1], words[2])
		end
	end
end


pdp13.hex_dump = hex_dump
pdp13.mem_dump = mem_dump
pdp13.convert_to_numbers = convert_to_numbers
