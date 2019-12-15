--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Disassembler

]]--

--
-- OP-codes
--
local Opcodes = {[0] =
    "nop:-:-", "halt:-:-", "call:ADR:-", "ret:-:-",
    "move:DST:SRC", "jump:ADR:-", "inc:DST:-", "dec:DST:-",
    "add:DST:SRC", "sub:DST:SRC", "mul:DST:SRC", "div:DST:SRC",
    "and:DST:SRC", "or:DST:SRC", "xor:DST:SRC", "not:DST:SRC",
    "bnze:DST:ADR", "bze:DST:ADR", "bpos:DST:ADR", "bneg:DST:ADR",
    "in:DST:CNST", "out:CNST:SRC", "push:SRC:-", "pop:DST:-", 
    "swap:DST:-", "dbnz:DST:ADR", "shl:DST:SRC", "shr:DST:SRC",
    "dly:-:-", "sys:CNST:-"
}

--
-- Operands
--
local Operands = {[0] =
    "A", "B", "C", "D", "X", "Y", "PC", "SP",
    "[X]", "[Y]", "[X]+", "[Y]+", "#0", "#1", "-", "-", 
    "IMM", "IND", "REL", "[SP+n]",
}

local OperandNeeded = { 
	IMM = "IMM", 
	IND = "IND",
	REL = "REL",
	["[SP+n]"] = "[SP+n]",
}

local function operand(address_mode, value)
	if address_mode == "IMM" then
		return string.format("#%04X", value)
	elseif address_mode == "IND" then
		return string.format("%04X", value)
	elseif address_mode == "REL" then
		if value >= 0x8000 then
			value = math.abs(value - 0x10000)
			return string.format("-%X", value)
		else
			return string.format("+%X", value)
		end
	elseif address_mode == "[SP+n]" then
		return string.format("[SP+%X]", value)
	else
		return address_mode
	end
end

local function operands(s2, s3, opcode2, opcode3)
	if s2 and OperandNeeded[s2] then
		s2 = operand(s2, opcode2)
		if s3 and OperandNeeded[s3] then
			s3 = operand(s3, opcode3)
			return 3, s2, s3
		end
		return 2, s2, s3
	elseif s3 and OperandNeeded[s3] then
		s3 = operand(s3, opcode2)
		return 2, s2, s3
	end
	return 1, s2, s3
end

local function lookup(opcode1, opcode2, opcode3)
	opcode1 = opcode1 or 0
	opcode2 = opcode2 or 0
	opcode3 = opcode3 or 0
	
	local idx1 = math.floor(opcode1 / 1024)
	local rest = opcode1 - (idx1 * 1024)
	local idx2 = math.floor(rest / 32)
	local idx3 = rest % 32
	local s = Opcodes[idx1]
	local num
	if s then
		local s1,s2,s3 = unpack(string.split(s, ":"))
		if s2 and s2 ~= "-" then
			s2 = Operands[idx2]
			if s3 and s3 ~= "-" then
				s3 = Operands[idx3]
				if s3 then
					num, s2, s3 = operands(s2, s3, opcode2, opcode3)
					return num, string.format("%-6s %s, %s", s1, s2, s3)
				end
			end
			num, s2, s3 = operands(s2, s3, opcode2, opcode3)
			return num, string.format("%-6s %s", s1, s2)
		end
		return 1, string.format("%s", s1)
	end
	return 1, string.format("%04X", opcode1)
end

-- addr is the start address
-- tOpcodes is the array of opcodes with two trailing 0x0000
-- blank is an alternative char for the standard ' '-sign
function pdp13.disassemble(addr, tOpcodes)
	local t = {}
	local idx = 1
	while tOpcodes[idx] do
		local num, s = lookup(tOpcodes[idx], tOpcodes[idx+1], tOpcodes[idx+2])
		if num == 1 then
			t[#t+1] = string.format("%04X: %04X           ; %s", addr, tOpcodes[idx], s)
		elseif num == 2 then
			t[#t+1] = string.format("%04X: %04X %04X      ; %s", addr, tOpcodes[idx], tOpcodes[idx+1] or 0, s)
		elseif num == 3 then
			t[#t+1] = string.format("%04X: %04X %04X %04X ; %s", addr, tOpcodes[idx], tOpcodes[idx+1] or 0, tOpcodes[idx+2] or 0, s)
		end
		addr = addr + num
		idx = idx + num
	end
	return addr, t
end
