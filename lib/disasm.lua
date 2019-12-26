--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Disassembler

]]--

local function operand(addr_type, addr_mode, value)
	if addr_mode == "IMM" then
		return string.format("#$%04X", value)
	elseif addr_mode == "IND" then
		return string.format("$%04X", value)
	elseif addr_mode == "REL" then
		if value >= 0x8000 then
			value = math.abs(value - 0x10000)
			return string.format("-%u", value)
		else
			return string.format("+%u", value)
		end
	elseif addr_mode == "[SP+n]" then
		return string.format("[SP+%u]", value)
	elseif addr_type == "-" then
		return nil
	else
		return addr_mode
	end
end

-- up to 3 words for one instruction
-- Returns the number of words and the instruction string
local function lookup(memw1, memw2, memw3)
	local idx1 = math.floor(memw1 / 1024)
	local opc1, opc2, opc3 = unpack(string.split(pdp13.VM13Opcodes[idx1], ":"))
	if opc1 then
		local rest = memw1 - (idx1 * 1024)
		local idx2 = math.floor(rest / 32)
		local idx3 = rest % 32
		local num = 1 + (idx2 >= 16 and 1 or 0) + (idx3 >= 16 and 1 or 0)
		
		if num == 3 then -- three words needed
			opc2 = operand(opc2, pdp13.VM13Operands[idx2], memw2)
			opc3 = operand(opc3, pdp13.VM13Operands[idx3], memw3)
		elseif idx1 < 4 then -- special opcodes
			opc2 =  string.format("%u", idx2 * 32 + idx3)
			opc3 = nil
			num = 1
		else
			opc2 = operand(opc2, pdp13.VM13Operands[idx2], memw2)
			opc3 = operand(opc3, pdp13.VM13Operands[idx3], memw2)
		end
		if opc2 and opc3 then
			return num, string.format("%-5s %s, %s", opc1, opc2, opc3)
		elseif opc2 then
			return num, string.format("%-5s %s", opc1, opc2)
		else
			return num, string.format("%s", opc1)
		end
	end
	
	return 1, string.format("%04X ???", memw1)
end

-- addr is the start address
function pdp13.disassemble(vm, addr)
	local mem = vm16.read_mem(vm, addr, 3)
	if mem then
		local num, s = lookup(mem[1], mem[2], mem[3])
		local tbl = {}
		for i = 1,num do tbl[i] = mem[i] end
		return num, tbl, s
	end
end

function pdp13.disasm_command(vm, s)
	local cmnd, val = string.match(s, "^([d]) +([0-9a-fA-F]+)$")
	if cmnd == "d" and val then
		local addr = tonumber(val, 16) or 0
		local num, tbl, str = pdp13.disassemble(vm, addr)
		local s = string.format("%04X: %-15s %s", addr, pdp13.hex_dump(tbl), str)
		return addr+num, s
	end
end
