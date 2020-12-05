--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Assembler

]]--

local tOpcodes = {}
local tOperands = {}

for idx,s in pairs(pdp13.VM13Opcodes) do
	local opc = string.split(s, ":")[1] 
	tOpcodes[opc] = idx
end

for idx,s in pairs(pdp13.VM13Operands) do
	tOperands[s] = idx
end

local function value(s)
	if string.sub(s, 1, 1) == "$" then
		return tonumber(string.sub(s, 2, -1), 16) or 0
	else
		return tonumber(s, 10) or 0	
	end
end

local function operand(s)
	if not s then return 0 end
	if tOperands[s] then
		return tOperands[s]
	end
	local c = string.sub(s, 1, 1)
	
	if c == "#" then return tOperands["IMM"], value(string.sub(s, 2, -1)) end
	if c == "$" then return tOperands["IND"], value(s) end
	if string.byte(c) >= 48 and string.byte(c) <= 57 then return tOperands["IND"], value(s) end
	if c == "+" or c == "-" then return tOperands["REL"], value(string.sub(s, 2, -1)) end
	if string.sub(s, 1, 4) == "[SP+" then return tOperands["[SP+n]"], value(string.sub(s, 5, -2)) end
	
	return 0
end

function pdp13.assemble(s)
	local opcode, opnd1, opnd2, val1, val2
	s = s:trim()
	if s == "" then return end
	s = string.gsub(s, ",", " ")
	local words = string.split(s, " ", false, 3)
	opcode = tOpcodes[words[1]]
	if not opcode then return end
	if words[2] and opcode < 4 then
		local num = value(words[2]) % 1024
		opnd1 = math.floor(num / 32)
		opnd2 = num % 32
	else
		opnd1, val1 = operand(words[2])
		opnd2, val2 = operand(words[3])
	end
	local tbl = {(opcode * 1024) + (opnd1 * 32) + opnd2}
	if val1 then tbl[#tbl+1] = val1 end
	if val2 then tbl[#tbl+1] = val2 end
	return tbl
end
