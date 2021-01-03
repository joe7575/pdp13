--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Assembler

]]--

local tOpcodes = {}
local tOperands = {}
local SymbolTbl = {}

for idx,s in pairs(pdp13.VM13Opcodes) do
	local opc = string.split(s, ":")[1] 
	tOpcodes[opc] = idx
end

for idx,s in pairs(pdp13.VM13Operands) do
	tOperands[s] = idx
end

local function const_val(s)
	if s and string.sub(s, 1, 1) == "#" then
		if string.sub(s, 2, 2) == "$" then
			return tonumber(string.sub(s, 3, -1), 16) or 0
		else
			return tonumber(string.sub(s, 2, -1), 10) or 0
		end
	else
		return 0	
	end
end

local function get_symbol(addr)
	for k,v in pairs(SymbolTbl) do
		if addr == v then
			return k
		end
	end
	return "???"
end

local function value(s, is_hex)
	if s then
		if string.sub(s, 1, 1) == "$" then
			return tonumber(string.sub(s, 2, -1), 16) or 0
		elseif is_hex then
			return tonumber(s, 16) or 0
		else
			return tonumber(s, 10) or 0
		end
	else
		return 0	
	end
end

local function operand(s, addr)
	if not s then return 0 end
	s = string.upper(s)
	if tOperands[s] then
		return tOperands[s]
	end
	if SymbolTbl[s] then -- jump destination
		return tOperands["IND"], SymbolTbl[s]
	end
	local c = string.sub(s, 1, 1)
	
	if c == "#" then return tOperands["IMM"], value(string.sub(s, 2, -1)) end
	if c == "$" then return tOperands["IND"], value(s) end
	-- value without '#' and '$'
	if string.byte(c) >= 48 and string.byte(c) <= 57 then return tOperands["IND"], value(s) end
	if c == "+" then return tOperands["REL"], value(string.sub(s, 2, -1)) end
	if c == "-" then return tOperands["REL"], 0x10000 - value(string.sub(s, 2, -1)) end
	if string.sub(s, 1, 4) == "[SP+" then return tOperands["[SP+n]"], value(string.sub(s, 5, -2)) end
	-- valid label keyword
	if string.find(s, "^%a%w+$") then
		SymbolTbl[s] = addr
		return tOperands["IND"], -1
	end
	return
end

function pdp13.assemble(s, addr)
	local opcode, opnd1, opnd2, val1, val2
	s = s:trim()
	if s == "" then return end
	s = string.gsub(s, ",", " ")
	local words = string.split(s, " ", false, 3)
	opcode = tOpcodes[words[1]]
	if not opcode then return end
	if words[2] and opcode < 4 then
		local num = const_val(words[2]) % 1024
		opnd1 = math.floor(num / 32)
		opnd2 = num % 32
	else
		opnd1, val1 = operand(words[2], addr)
		opnd2, val2 = operand(words[3], addr)
	end
	-- some checks
	if val1 and val2 then return end
	if not opnd1 and not opnd2 then return end
	-- code correction for all jump/branch opcodes: from '0' to '#0'
	if pdp13.JumpInst[words[1]] then
		if opnd1 == tOperands["IND"] then opnd1 = tOperands["IMM"] end
		if opnd2 == tOperands["IND"] then opnd2 = tOperands["IMM"] end
	end
	-- calculate opcode
	local tbl = {(opcode * 1024) + (opnd1 * 32) + opnd2}
	if val1 then tbl[#tbl+1] = val1 end
	if val2 then tbl[#tbl+1] = val2 end
	return tbl
end

-- Label address resolution
local function replace_placeholder(tbl, addr)
	if tbl then
		if tbl[1] == -1 then 
			tbl[1] = addr
		elseif tbl[2] == -1 then 
			tbl[2] = addr 
		end
	end
end

-- for ASM text blocks
local function text_to_table(line)
	local tbl = {}
	for i = 1, #line do
		if string.byte(line, i) == 92 and  string.byte(line, i+1) == 48 then  -- '\0'
			tbl[#tbl+1] = 0
			return tbl
		else
			tbl[#tbl+1] = string.byte(line, i)
		end
	end
	return tbl
end

-- generate one data line for H16 file
local function h16_line(addr, tbl)
	local t2 = {}
	for _,val in ipairs(tbl or {}) do
		if val == -1 then  -- unsolved
			return
		else
			t2[#t2+1] = string.format("%04X", val)
		end
	end
	local s = string.format("%04X", addr)
	return ":"..#tbl..s.."00"..table.concat(t2, "")
end

-- generate H16 text block
local function table_to_h16(code)
	-- first sort by addresses
	local addrs = {}
	for addr,_ in pairs(code) do
		addrs[#addrs+1] = addr
	end
	table.sort(addrs)
	
	-- generate text lines
	local t1 = {}
	for _,addr in ipairs(addrs) do
		local t2 = code[addr]
		if t2 then
			local tbl = h16_line(addr, t2)
			if tbl then
				t1[#t1+1] = h16_line(addr, t2)
			else
				local symbol = get_symbol(addr)
				return nil, "Error: Unresolved label '"..symbol.."'"
			end
		end
	end
	t1[#t1+1] = ":00000FF"
	return table.concat(t1, "\n")
end

-- text is the complete ASM file with comments, ".text", ".code", and ".org" keywords
function pdp13.assemble2(text)
	SymbolTbl = {} -- reset
	local code = {}
	local is_text = false
	local addr = 0
	
	for idx, line in ipairs(string.split(text or "", "\n")) do
		line = line:trim()
		if line ~= "" then
			line = string.split(line, ";", true, 1)[1]
			line = line:trim()
			if line ~= "" then
				local words = string.split(line, " ", false, 3)
				if string.byte(line, -1) == 58 then -- ':'-label
					local lbl = string.sub(line, 1, -2)
					lbl = string.upper(lbl)
					if SymbolTbl[lbl] then
						replace_placeholder(code[SymbolTbl[lbl]], addr)
					else
						SymbolTbl[lbl] = addr
					end
				elseif is_text then
					-- valid text string
					if string.byte(line, 1) == 34 and string.byte(line, -1) == 34 then  -- "..."
						-- divide in chunks with 8 characters (H16 limitation)
						for i = 2, string.len(line) - 1, 8 do
							local s = string.sub(line, i, i+7)
							local tbl = text_to_table(s)		
							code[addr] = tbl
							addr = addr + #tbl
						end
					end
				elseif words[1] == ".org" then
					addr = value(words[2])
				elseif line == ".text" then
					is_text = true
				elseif line == ".code" then
					is_text = false
				else -- normal code
					local tbl = pdp13.assemble(line, addr)
					if tbl then
						code[addr] = tbl
						addr = addr + #tbl
					else
						return nil, string.format("Error (%u): %s", idx, line)
					end
				end
			end
		end
	end
	
	-- return the H16 text block
	return table_to_h16(code)
end

-- pdp13.string_to_number(s, is_hex): returns number  -- suports dec and hex $...
pdp13.string_to_number = value
