--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

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


-- table with up to 3 words for one instruction
-- Returns the number of words and the instruction string
function pdp13.disassemble(mem)
	local idx1 = math.floor(mem[1] / 1024)
	local opc1, opc2, opc3 = unpack(string.split(pdp13.VM13Opcodes[idx1] or "", ":"))
	if opc1 then
		if opc2 == "NUM" then
			return 1, string.format("%-4s %u", opc1, mem[1] % 1024)
		else
			local rest = mem[1] - (idx1 * 1024)
			local idx2 = math.floor(rest / 32)
			local idx3 = rest % 32
			local num = 1 + (idx2 >= 16 and 1 or 0) + (idx3 >= 16 and 1 or 0)
		
			if num == 3 then -- three words needed
				opc2 = operand(opc2, pdp13.VM13Operands[idx2], mem[2])
				opc3 = operand(opc3, pdp13.VM13Operands[idx3], mem[3])
			else
				opc2 = operand(opc2, pdp13.VM13Operands[idx2], mem[2])
				opc3 = operand(opc3, pdp13.VM13Operands[idx3], mem[2])
			end
			if opc2 and opc3 then
				return num, string.format("%-4s %s, %s", opc1, opc2, opc3)
			elseif opc2 then
				return num, string.format("%-4s %s", opc1, opc2)
			else
				return num, string.format("%s", opc1)
			end
		end
	end
	
	return 1, string.format("%04X ???", mem[1])
end
