--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Monitor program

]]--

-- for lazy programmers
local M = minetest.get_meta

local Commands = {}  -- [cmnd] = func(pos, mem, cmd, rest): returns list of output strings

local function hex_dump(tbl)
	local t2 = {}
	for _,val in ipairs(tbl or {}) do
		t2[#t2+1] = string.format("%04X", val)
	end
	return table.concat(t2, " ")
end

local function ascii(val)
	local hb = val / 256
	local lb = val % 256 
	hb = (hb > 31 and hb < 128) and string.char(hb) or "."
	lb = (lb > 31 and lb < 128) and string.char(lb) or "."
	return hb..lb
end

local function mem_dump(pos, addr, mem, is_terminal)
	local lines = {}
	if is_terminal then
		for i = 1, (#mem/4) do
			local offs = (i - 1) * 4
			lines[i] = string.format("%04X: %04X %04X %04X %04X  %s", 
					addr+offs, mem[1+offs], mem[2+offs], mem[3+offs], mem[4+offs],
					ascii(mem[1+offs])..ascii(mem[2+offs])..ascii(mem[3+offs])..ascii(mem[4+offs]))
		end
	else
		for i = 1, (#mem/4) do
			local offs = (i - 1) * 4
			lines[i] = string.format("%04X: %04X %04X %04X %04X", 
					addr+offs, mem[1+offs], mem[2+offs], mem[3+offs], mem[4+offs])
		end
	end
	return lines
end

local function convert_to_numbers(s)
	local tbl = {}
	if s and s ~= "" then
		for _,val in ipairs(string.split(s, " ")) do
			tbl[#tbl+1] = pdp13.string_to_number(val, true)
		end
	end
	return tbl
end

-- st(art)  s(to)p  r(ese)t  n(ext)  r(egister)  ad(dress)  d(ump)  en(ter)
Commands["?"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor then
		mem.mstate = nil
		if is_terminal then
			return {
				"st [#].start            sp ....stop",
				"rt ....reset            n .....next step [F1]",
				"r .....register [F3]    ad # ..set address",
				"d # ...dump memory      en # ..enter data",
				"as # ..assemble         di # ..disassemble",
				"br # ..set brkpoint     br ....rst brkpoint",
				"so ....step over [F2]   ps ....pipe size",
				"ld name ....load a .com/.h16 file",
				"ct # txt ...copy text to mem",
				"cm # # # ...copy mem from to num",
				"sy # # # ...call 'sys num A B'",
				"ex .........exit monitor",
			}
		else
			return {
				"?         help",
				"st [#]    start",
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
	end
end

-- start
Commands["st"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		if rest ~= "" then
			local addr = pdp13.string_to_number(rest, true)
			vm16.set_pc(pos, addr)
		end
--		if mem.bp_val then
--			vm16.breakpoint_step2(pos, mem.brkp_addr, mem.bp_val)
--			mem.bp_val = nil
--		end
		pdp13.start_cpu(pos)
		mem.mstate = nil
		return {"running"}
	end
end

-- stop
Commands["sp"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		pdp13.stop_cpu(pos)
		mem.mstate = nil
		local cpu, sts = vm16.get_cpu_reg(pos), false
--		cpu, sts = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	end
end

-- reset
Commands["rt"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		vm16.set_pc(pos, 0) 
		mem.mstate = nil
		local cpu, sts = vm16.get_cpu_reg(pos), false
--		cpu, sts = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	end
end

-- next step
Commands["n"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
--		if mem.bp_val then
--			mem.bp_val = vm16.breakpoint_step2(pos, mem.brkp_addr, mem.bp_val)
--		else
			pdp13.single_step_cpu(pos)
--		end
		mem.mstate = 'n'
		local cpu, sts = vm16.get_cpu_reg(pos), false
--		cpu, sts = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	end
end

Commands["\028"] = Commands["n"]
	
-- register
Commands["r"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor then
		local cpu = vm16.get_cpu_reg(pos)
		mem.mstate = nil
		return {
			string.format("A:%04X  B:%04X   C:%04X   D:%04X", cpu.A, cpu.B, cpu.C, cpu.D),
			string.format("X:%04X  Y:%04X  PC:%04X  SP:%04X", cpu.X, cpu.Y, cpu.PC, cpu.SP),
		}
	end
end

Commands["\030"] = Commands["r"]
	
-- set address
Commands["ad"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		local addr = pdp13.string_to_number(rest, true)
		mem.mstate = nil
		vm16.set_pc(pos, addr) 
		local cpu, sts = vm16.get_cpu_reg(pos), false
--		cpu, sts = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	end
end
	
-- dump memory
Commands["d"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor then
		if cmd == "d" then
			mem.mstate = "d"
			mem.maddr = pdp13.string_to_number(rest, true)
		else
			mem.maddr = mem.maddr or 0
		end
		local dump = vm16.read_mem(pos, mem.maddr, 16)
		local addr = mem.maddr
		mem.maddr = mem.maddr + 16
		if dump then
			return mem_dump(pos, addr, dump, is_terminal)
		end
		return {"Address error"}
	end
end

local function make_table(text)
	local t = {}
	for s in text:gmatch("[^\n]+") do
		s = "sm: "..s:sub(1, 44)
		table.insert(t, s)
	end
	return t
end

-- dump pipe size
Commands["ps"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor and is_terminal then
		local size = pdp13.pipe_size(pos)
		return {"pipe size = "..size}
	end
end

-- enter data
Commands["en"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		if cmd == "en" then
			mem.mstate = "en"
			mem.maddr = pdp13.string_to_number(rest, true)
			return {string.format("%04X: ", mem.maddr)}
		else
			local tbl = convert_to_numbers(rest)
			local addr = mem.maddr
			mem.maddr = mem.maddr + #tbl
			vm16.write_mem(pos, addr, tbl)
			return {string.format("%04X: %s", addr, hex_dump(tbl))}
		end
	end
end
		
-- assemble
Commands["as"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		if cmd == "as" then
			mem.mstate = "as"
			mem.maddr = pdp13.string_to_number(rest, true)
			return {"ASM ('ex' to exit)", string.format("%04X: ", mem.maddr)}
		else
			local tbl = pdp13.assemble(rest)
			if tbl then
				vm16.write_mem(pos, mem.maddr, tbl)
				local addr = mem.maddr
				mem.maddr = mem.maddr + #tbl
				return {string.format("%04X: %-11s %s", addr, hex_dump(tbl), rest)}
			elseif rest == "ex" then
				mem.mstate = nil
				return {"exit."}
			else
				return {rest.." <-- syntax error!"}
			end
		end
	end
end

-- disassemble
Commands["di"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		if cmd == "di" then
			mem.mstate = "di"
			if rest ~= "" then
				mem.maddr = pdp13.string_to_number(rest, true)
			else
				mem.maddr = vm16.get_pc(pos)
			end
		else
			mem.maddr = mem.maddr or 0
		end
		local dump = vm16.read_mem(pos, mem.maddr, 8)
		local tbl = {}
		local offs = 1
		for i = 1, 4 do
			local cpu = {PC = mem.maddr + offs - 1, mem0 = dump[offs], mem1 = dump[offs+1]}
			local sts
--			cpu, sts = patch_breakpoint(cpu, mem)
			local num, s = pdp13.disassemble(cpu, mem, sts)
			offs = offs + num
			tbl[#tbl+1] = s
		end
		mem.maddr = mem.maddr + offs - 1
		return tbl
	end
end

-- set/reset breakpoint
Commands["br"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor and is_terminal then
		mem.mstate = nil
		local words = string.split(rest, " ", true, 1)
		if rest ~= "" and #words == 1 then
			if mem.brkp_addr then
				vm16.reset_breakpoint(pos, mem.brkp_addr, mem.breakpoints)
			end
			local addr = pdp13.string_to_number(words[1], true)
			mem.brkp_addr = addr
			mem.breakpoints = mem.breakpoints or {}
			vm16.set_breakpoint(pos, addr, mem.breakpoints)
			return {"breakpoint set"}
		elseif mem.brkp_addr then
			vm16.reset_breakpoint(pos, mem.brkp_addr, mem.breakpoints)
			mem.brkp_addr = nil
--			mem.brkp_code = nil
			return {"breakpoint reset"}
		end
	end
	return {"error!"}
end

-- step over (a call opcode)
Commands["so"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor and is_terminal then
		local cpu, sts = vm16.get_cpu_reg(pos), false
		local opcode = math.floor(cpu.mem0 / 1024)
		if opcode == 5 then
			local addr = string.format("%X", cpu.PC + 2)
			Commands["br"](pos, mem, "br", addr, is_terminal)
			Commands["st"](pos, mem, "st", "", is_terminal)
			
			cpu, sts = vm16.get_cpu_reg(pos)
--			cpu, sts = patch_breakpoint(cpu, mem)
			local num, s = pdp13.disassemble(cpu, mem, sts)
			mem.mstate = "n"
			return {}
		end
	end
	return {"error!"}
end

Commands["\029"] = Commands["so"]

-- copy text
Commands["ct"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		mem.mstate = nil
		local words = string.split(rest, " ", true, 1)
		if #words == 2 then
			local addr = pdp13.string_to_number(words[1], true)
			vm16.write_ascii(pos, addr, words[2])
			return {"text copied"}
		end
		return {"error!"}
	end
end

-- copy memory
Commands["cm"] = function(pos, mem, cmd, rest)
	if pdp13.get_nvm(pos).monitor then
		mem.mstate = nil
		local words = string.split(rest, " ", false, 2)
		if #words == 3 then
			local src_addr = pdp13.string_to_number(words[1], true)
			local dst_addr = pdp13.string_to_number(words[2], true)
			local number = pdp13.string_to_number(words[3], true)
			if src_addr and dst_addr and number then
				local tbl = vm16.read_mem(pos, src_addr, number)
				vm16.write_mem(pos, dst_addr, tbl)
				return {"memory copied"}
			end
		end
		return {"error!"}
	end
end

-- sys command
Commands["sy"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor and is_terminal then
		mem.mstate = nil
		local num, regA, regB = unpack(string.split(rest, " ", false, 2))
		num = pdp13.string_to_number(num, true)
		regA = pdp13.string_to_number(regA, true) or 0
		regB = pdp13.string_to_number(regB, true) or 0
		
		if num and num < 0x300 then
			local sts, resp = pcall(pdp13.sys_call, pos, num, regA, regB)
			if sts then
				return {"result = "..(resp or 65535)}
			else
				return {"sys error", resp:sub(1, 48)}
			end
		end
		return {"error!"}
	end
end

-- load file
Commands["ld"] = function(pos, mem, cmd, rest, is_terminal)
	if pdp13.get_nvm(pos).monitor and is_terminal then
		local resp
		if pdp13.path.has_ext(rest, "com") and pdp13.boot.file_exists(pos, rest) then
			resp = pdp13.boot.load_comfile(pos, rest)
		elseif pdp13.path.has_ext(rest, "h16") and pdp13.boot.file_exists(pos, rest) then
			resp = pdp13.boot.load_h16file(pos, rest)
		else
			return {"error!"}
		end
		return {"result = "..resp}
	end
end

-- exit monitor
Commands["ex"] = function(pos, mem, cmd, rest)
	pdp13.get_nvm(pos).monitor = false
	mem.monitor = nil
	pdp13.exit_monitor(pos)
	return {"finished."}
end

function pdp13.monitor_init(pos, mem)
	mem.mstate = nil
	mem.brkp_addr = nil
--	mem.brkp_code = nil
--	mem.bp_val = nil
	mem.maddr = nil
end	

function pdp13.monitor(cpu_pos, mem, command, is_terminal)
	if cpu_pos and mem and command then
		local words = string.split(command, " ", false, 1)
		local resp
		
		if mem.mstate == "as" then
			resp = Commands[mem.mstate](cpu_pos, mem, "", command, is_terminal)
		elseif Commands[words[1]] then
			resp = Commands[words[1]](cpu_pos, mem, words[1], words[2] or "", is_terminal)
		elseif mem.mstate and Commands[mem.mstate] then
			resp = Commands[mem.mstate](cpu_pos, mem, "", command, is_terminal)
		else
			resp = Commands["?"](cpu_pos, mem, words[1], words[2] or "", is_terminal)
		end
		if command ~= "" and mem.mstate ~= "as" and string.byte(command, 1) > 32 then -- don't return function keys
			return "[mon]$ "..command, resp
		else
			return nil, resp
		end
	end
end

function pdp13.monitor_stopped(cpu_pos, mem, resp, is_terminal)
	if is_terminal and resp == vm16.BREAK then
		local cpu, sts = vm16.get_cpu_reg(cpu_pos), false
--		if mem.brkp_addr and mem.brkp_addr + 1 == cpu.PC then 
--			mem.bp_val = vm16.breakpoint_step1(cpu_pos, mem.brkp_addr, mem.brkp_code)
--		end
		cpu = vm16.get_cpu_reg(cpu_pos)
--		cpu, sts = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	elseif not is_terminal and resp == vm16.BREAK then
		local cpu, sts = vm16.get_cpu_reg(cpu_pos), false
		local num, s = pdp13.disassemble(cpu, mem, sts)
		return {s}
	elseif not mem.mstate then
		return {"stopped: "..(vm16.CallResults[resp] or "")}
	end
end

pdp13.hex_dump = hex_dump
pdp13.mem_dump = mem_dump
pdp13.convert_to_numbers = convert_to_numbers
