--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Disassembler

]]--

local function operand(addr_type, addr_mode, value)
	if addr_mode == "IMM" then
		return string.format("#$%X", value)
	elseif addr_mode == "IND" then
		return string.format("$%X", value)
	elseif addr_mode == "REL" then
		if value >= 0x8000 then
			value = math.abs(value - 0x10000)
			return string.format("-$%X", value)
		else
			return string.format("+$%X", value)
		end
	elseif addr_mode == "[SP+n]" then
		return string.format("[SP+%u]", value)
	elseif addr_type == "-" then
		return nil
	else
		return addr_mode
	end
end

-- Returns the number of operands (0,1) based on the given opcode
function pdp13.num_operands(opcode)
	local idx1 = math.floor(opcode / 1024)
	local rest = opcode - (idx1 * 1024)
	local idx2 = math.floor(rest / 32)
	local idx3 = rest % 32
	return math.min((idx2 >= 16 and 1 or 0) + (idx3 >= 16 and 1 or 0), 1)
end

local function indexes(cpu)
	local idx1 = math.floor(cpu.mem0 / 1024)
	local rest = cpu.mem0 - (idx1 * 1024)
	local idx2 = math.floor(rest / 32)
	local idx3 = rest % 32
	local num = 1 + (idx2 >= 16 and 1 or 0) + (idx3 >= 16 and 1 or 0)
	if idx1 < 4 then num = 1 end
	return idx1, idx2, idx3, num
end	
	
local function dump(cpu, num)
	if num == 1 then
		return string.format("%04X: %04X     ", cpu.PC, cpu.mem0)
	else
		return string.format("%04X: %04X %04X", cpu.PC, cpu.mem0, cpu.mem1)
	end
end

-- Returns the number of words and the instruction string
function pdp13.disassemble(cpu, mem, is_breakpoint)
	local idx1, idx2, idx3, num = indexes(cpu)
	local s = dump(cpu, num)
	local opc1, opc2, opc3 = unpack(string.split(pdp13.VM16Opcodes[idx1] or "", ":"))
	local star = is_breakpoint and "*" or " "
	if opc1 then
		-- code correction for all jump/branch opcodes: from '#0' to '0'
		if pdp13.JumpInst[opc1] then
			 if idx2 == 16 then idx2 = 17 end
			 if idx3 == 16 then idx3 = 17 end
		end
		if opc1 == "sys" and opc2 == "CNST" then
			return 1, string.format("%s  %s%-4s #$%X", s, star, opc1, cpu.mem0 % 1024)
		elseif opc1 == "brk" and opc2 == "CNST" then
			return 1, string.format("%s  %sbrk #%u", s, star, cpu.mem0 % 1024)
		else
			opc2 = operand(opc2, pdp13.VM16Operands[idx2], cpu.mem1)
			opc3 = operand(opc3, pdp13.VM16Operands[idx3], cpu.mem1)
			
			if opc2 and opc3 then
				return num, string.format("%s  %s%-4s %s, %s", s, star, opc1, opc2, opc3)
			elseif opc2 then
				return num, string.format("%s  %s%-4s %s", s, star, opc1, opc2)
			else
				return num, string.format("%s  %s%s", s, star, opc1)
			end
		end
	end
	
	return 1, s.."  ???"
end
