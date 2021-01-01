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
			tbl[#tbl+1] = pdp13.string_to_number(val)
		end
	end
	return tbl
end

local function patch_breakpoint(cpu, mem)
	if cpu.mem0 == 0x400 and mem.brkp_code then
		cpu.mem0 = mem.brkp_code
	end
	return cpu
end

-- st(art)  s(to)p  r(ese)t  n(ext)  r(egister)  ad(dress)  d(ump)  en(ter)
Commands["?"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor then
		mem.mstate = nil
		if is_terminal then
			return {
				"st [#].start            sp.....stop",
				"rt.....reset            n......next step",
				"r......register         ad #...set address",
				"d #....dump memory      en #...enter data",
				"as #...assemble         di #...disassemble",
				"br #...set brkpoint     br.....rst brkpoint",
				"",
				"ld name.....load a .com/.h16 file",
				"ct # txt....copy text to mem",
				"cm # # #....copy mem from to num",
				"sys # # #...call 'sys num A B'",
				"ex..........exit monitor",
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
	if techage.get_nvm(pos).monitor then
		if rest ~= "" then
			local addr = pdp13.string_to_number(rest)
			vm16.set_pc(pos, addr)
		end
		pdp13.start_cpu(pos)
		mem.mstate = nil
		return {"running"}
	end
end

-- stop
Commands["sp"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
		pdp13.stop_cpu(pos)
		mem.mstate = nil
		local cpu = vm16.get_cpu_reg(pos)
		cpu = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem)
		return {s}
	end
end

-- reset
Commands["rt"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
		vm16.set_pc(pos, 0) 
		mem.mstate = nil
		local cpu = vm16.get_cpu_reg(pos)
		cpu = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem)
		return {s}
	end
end

-- next step
Commands["n"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
		pdp13.single_step_cpu(pos)
		mem.mstate = 'n'
		local cpu = vm16.get_cpu_reg(pos)
		cpu = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem)
		return {s}
	end
end
	
-- register
Commands["r"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor then
		local cpu = vm16.get_cpu_reg(pos)
		mem.mstate = nil
		if is_terminal then
			return {
				string.format("A:%04X B:%04X C:%04X D:%04X", cpu.A, cpu.B, cpu.C, cpu.D).." "..
				string.format("X:%04X Y:%04X PC:%04X SP:%04X", cpu.X, cpu.Y, cpu.PC, cpu.SP),
			}
		else
			return {
				string.format("A:%04X B:%04X C:%04X D:%04X", cpu.A, cpu.B, cpu.C, cpu.D),
				string.format("X:%04X Y:%04X P:%04X S:%04X", cpu.X, cpu.Y, cpu.PC, cpu.SP),
			}
		end
	end
end

-- set address
Commands["ad"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
		local addr = pdp13.string_to_number(rest)
		mem.mstate = nil
		vm16.set_pc(pos, addr) 
		local cpu = vm16.get_cpu_reg(pos)
		cpu = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem)
		return {s}
	end
end
	
-- dump memory
Commands["d"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor then
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
			return mem_dump(pos, addr, dump, is_terminal)
		end
		return {"Address error"}
	end
end

-- enter data
Commands["en"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
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
end
		
-- assemble
Commands["as"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
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
end

-- disassemble
Commands["di"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
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
			cpu = patch_breakpoint(cpu, mem)
			local num, s = pdp13.disassemble(cpu, mem)
			offs = offs + num
			tbl[#tbl+1] = s
		end
		mem.maddr = mem.maddr + offs - 1
		return tbl
	end
end

-- set/reset breakpoint
Commands["br"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor and is_terminal then
		mem.mstate = nil
		local words = string.split(rest, " ", true, 1)
		if rest ~= "" and #words == 1 then
			if mem.brkp_addr then
				vm16.reset_breakpoint(pos, mem.brkp_addr, mem.brkp_code)
			end
			local addr = pdp13.string_to_number(words[1])
			mem.brkp_addr = addr
			mem.brkp_code = vm16.set_breakpoint(pos, addr, 0)
			return {"breakpoint set"}
		elseif mem.brkp_addr then
			vm16.reset_breakpoint(pos, mem.brkp_addr, mem.brkp_code)
			mem.brkp_addr = nil
			mem.brkp_code = nil
			return {"breakpoint reset"}
		end
	end
	return {"error!"}
end

-- copy text
Commands["ct"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
		mem.mstate = nil
		local words = string.split(rest, " ", true, 1)
		if #words == 2 then
			local addr = pdp13.string_to_number(words[1])
			vm16.write_ascii(pos, addr, words[2].."\000")
			return {"text copied"}
		end
		return {"error!"}
	end
end

-- copy memory
Commands["cm"] = function(pos, mem, cmd, rest)
	if techage.get_nvm(pos).monitor then
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
end

-- sys command
Commands["sys"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor and is_terminal then
		mem.mstate = nil
		local num, regA, regB = unpack(string.split(rest, " ", false, 2))
		num = pdp13.string_to_number(num)
		regA = pdp13.string_to_number(regA) or 0
		regB = pdp13.string_to_number(regB) or 0
		
		if num then
			print(5)
			local sts, resp = pcall(pdp13.sys_call, pos, num, regA, regB)
			print(6)
			if sts then
			print(7)
				return {"result = "..resp}
			else
				return {"sys error", resp:sub(1, 48)}
			end
		end
		return {"error!"}
	end
end

-- load file
Commands["ld"] = function(pos, mem, cmd, rest, is_terminal)
	if techage.get_nvm(pos).monitor and is_terminal then
		local sts, resp
		if pdp13.is_com_file(rest) and pdp13.file_exists(pos, rest) then
			sts, resp = pcall(pdp13.sys_call, pos, pdp13.LOAD_COM, rest, 0, pdp13.PARAM_BUFF)
		elseif pdp13.is_h16_file(rest) and pdp13.file_exists(pos, rest) then
			sts, resp = pcall(pdp13.sys_call, pos, pdp13.LOAD_H16, rest, 0, pdp13.PARAM_BUFF)
		else
			return {"error!"}
		end
		if sts then
			return {"result = "..resp}
		else
			return {"sys error", resp:sub(1, 48)}
		end
	end
end

-- exit monitor
Commands["ex"] = function(pos, mem, cmd, rest)
	techage.get_nvm(pos).monitor = false
	pdp13.exit_monitor(pos)
	return {"finished."}
end


function pdp13.monitor(cpu_pos, mem, command, is_terminal)
	if cpu_pos and mem and command then
		local words = string.split(command, " ", false, 1)
		local resp
		
		if Commands[words[1]] then
			resp = Commands[words[1]](cpu_pos, mem, words[1], words[2] or "", is_terminal)
		elseif mem.mstate and Commands[mem.mstate] then
			resp = Commands[mem.mstate](cpu_pos, mem, "", command, is_terminal)
		else
			resp = Commands["?"](cpu_pos, mem, words[1], words[2] or "", is_terminal)
		end
		if command ~= "" then
			return "[mon]$ "..command, resp
		else
			return nil, resp
		end
	end
end

function pdp13.monitor_stopped(cpu_pos, mem, resp, is_terminal)
	if is_terminal and resp == vm16.BREAK and mem.brkp_addr then
		vm16.breakpoint_step(cpu_pos, mem.brkp_addr, mem.brkp_code)
		local cpu = vm16.get_cpu_reg(cpu_pos)
		cpu = patch_breakpoint(cpu, mem)
		local num, s = pdp13.disassemble(cpu, mem)
		return {s}
	elseif not mem.mstate then
		return {"stopped: "..(vm16.CallResults[resp] or "")}
	end
end

pdp13.hex_dump = hex_dump
pdp13.mem_dump = mem_dump
pdp13.convert_to_numbers = convert_to_numbers
