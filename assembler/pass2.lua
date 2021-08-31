--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Assembler pass2
	- add identifier to symbol table
    - collect namespaces
	- return a list with {type, lineno, address, code, line}
]]--

local asm = ...
asm.tSymbols = {}

local tNamespaces = {}
local tOpcodes = {}
local tOperands = {}

local IDENT = "^[A-Za-z_][A-Za-z_0-9%.]+"

for idx,s in pairs(pdp13.VM16Opcodes) do
	local opc = string.split(s, ":")[1] 
	tOpcodes[opc] = idx
end

for idx,s in pairs(pdp13.VM16Operands) do
	tOperands[s] = idx
end

local tSections = {
	[".data"] = asm.DATASEC,	[".code"] = asm.CODESEC,
	[".text"] = asm.TEXTSEC,
	[".ctext"] = asm.CTEXTSEC,
}

local function strsplit(s)
	local words = {}
	string.gsub(s, "([^%s,]+)", function(w)
		table.insert(words, w)
	end)
	return words
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

-- Expand an identifier like 'foo' to:
--           foo.start
-- namespace.foo
-- depending on foo is a valid namespace or not. 
local function expand_ident(pos, ident)
	local _, _, first, second = ident:find("^(.*)%.(.*)$")
	
	if not first then
		if tNamespaces[ident] then
			return ident .. ".start"
		else
			return asm.namespace .. "." .. ident
		end
	else
		if tNamespaces[first] then
			return ident
		else
			asm.err_msg(pos, "Invalid symbol")
		end
	end
end

local function value(pos, s, is_hex)
	if s:match(IDENT) then
		asm.type = asm.CODESYMSEC
		return expand_ident(pos, s)
	end
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

local function operand(pos, s)
	if not s then return 0 end
	local s2 = string.upper(s)
	if tOperands[s2] then
		return tOperands[s2]
	end
	local c = string.sub(s, 1, 1)
	
	if c == "#" then return tOperands["IMM"], value(pos, string.sub(s, 2, -1)) end
	if c == "$" then return tOperands["IND"], value(pos, s) end
	-- value without '#' and '$'
	if string.byte(c) >= 48 and string.byte(c) <= 57 then return tOperands["IND"], value(pos, s) end
	if c == "+" then return tOperands["REL"], value(pos, string.sub(s, 2, -1)) end
	if c == "-" then return tOperands["REL"], 0x10000 - value(pos, string.sub(s, 2, -1)) end
	if string.sub(s, 1, 4) == "[SP+" then return tOperands["[SP+n]"], value(pos, string.sub(s, 5, -2)) end
	-- valid label keyword
	if s:match(IDENT) then
		asm.type = asm.CODESYMSEC
		local ident = expand_ident(pos, s)
		return tOperands["IND"], ident
	end
	return
end

local function decode_code(pos, lToken, lineno, text)
	local words = strsplit(text)
	--print(lineno, words[1] or "", words[2] or "", words[3] or "")

	-- Aliases
	if words[2] == "=" then
		if words[1]:match(IDENT) then
			local ident = expand_ident(pos, words[1])
			asm.tSymbols[ident] = value(pos, words[3])
		else
			asm.err_msg(pos, "Invalid left value")
		end
		return
	end
		
	-- Opcodes
	local opcode, opnd1, opnd2, val1, val2
	
	opcode = tOpcodes[words[1]]
	if not opcode then 
		asm.err_msg(pos, "Syntax error")
		return 
	end
	if #words == 2 and opcode < 4 then
		local num = const_val(words[2]) % 1024
		opnd1 = math.floor(num / 32)
		opnd2 = num % 32
	else
		opnd1, val1 = operand(pos, words[2], asm.address)
		opnd2, val2 = operand(pos, words[3], asm.address)
	end
	-- some checks
	if val1 and val2 then 
		asm.err_msg(pos, "Syntax error")
		return 
	end
	if not opnd1 and not opnd2 then 
		asm.err_msg(pos, "Syntax error")
		return 
	end
	-- code correction for all jump/branch opcodes: from '0' to '#0'
	if pdp13.JumpInst[words[1]] then
		if opnd1 == tOperands["IND"] then opnd1 = tOperands["IMM"] end
		if opnd2 == tOperands["IND"] then opnd2 = tOperands["IMM"] end
	end
	-- calculate opcode
	local tbl = {(opcode * 1024) + (opnd1 * 32) + opnd2}
	if val1 then tbl[#tbl+1] = val1 end
	if val2 then tbl[#tbl+1] = val2 end
	
	table.insert(lToken, {asm.type, lineno, asm.address, tbl, text})
	asm.address = asm.address + #tbl
end	

local function decode_data(pos, lToken, lineno, text)
	local words = strsplit(text)
	local tbl = {}
	for _,word in ipairs(words) do
		if word then
			table.insert(tbl, value(pos, word))
		end
	end
	table.insert(lToken, {asm.type, lineno, asm.address, tbl, text})
	asm.address = asm.address + #tbl
end

local function decode_text(pos, lToken, lineno, text)
	if text:byte(1) == 34 and text:byte(-1) == 34 then
		text = text:gsub("\\0", "\0")
		text = text:gsub("\\n", "\n")
		text = text:sub(2, -2)
		local ln = #text
		
		for idx = 1, ln, 8 do
			local tbl = {}
			for i = idx, math.min(idx + 7, ln) do
				table.insert(tbl, text:byte(i))
			end
			table.insert(lToken, {asm.type, lineno, asm.address, tbl, text:sub(idx, idx + 7)})
			asm.address = asm.address + #tbl
		end
	else
		asm.err_msg(pos, "Invalid string")
		return
	end
end

local function word_val(s, idx)
	if s:byte(idx) == 0 then
		return 0 
	elseif idx == #s then
		return s:byte(idx)
	elseif s:byte(idx+1) == 0 then
		return s:byte(idx)
	else
		return (s:byte(idx) * 256) + s:byte(idx+1)
	end
end

local function decode_ctext(pos, lToken, lineno, text)
	if text:byte(1) == 34 and text:byte(-1) == 34 then
		text = text:gsub("\\0", "\0\0")
		text = text:gsub("\\n", "\n")
		text = text:sub(2, -2)
		local ln = #text
		
		for idx = 1, ln, 16 do
			local tbl = {}
			for i = idx, math.min(idx + 15, ln), 2 do
				table.insert(tbl, word_val(text, i))
			end
			table.insert(lToken, {asm.type, lineno, asm.address, tbl, text:sub(idx, idx + 15)})
			asm.address = asm.address + #tbl
		end
	else
		asm.err_msg(pos, "Invalid string")
		return
	end
end

local function address_label(pos, text)
	local _, pos, label = text:find("^([A-Za-z_][A-Za-z_0-9%.]+):( *)")
	if label then
		label = expand_ident(pos, label)
		asm.tSymbols[label] = asm.address
		return text:sub(pos+1, -1)
	end
	return text
end		

local function section(pos, text)	
	-- New assembler section
	if tSections[text] then
		asm.section = tSections[text]
		if text == ".code" then
			local label = asm.namespace .. ".start"
			if not asm.tSymbols[label] then
				asm.tSymbols[label] = asm.address
			end
		end
		return ""
	end
	return text
end

local function org_directive(pos, text)
	local _, _, addr = text:find("^%.org +([%$%x]+)$")
	if addr then
		asm.address = value(pos, addr)
		return ""
	end
	return text
end	


function asm.pass2(pos, lToken1)
	asm.outp(pos, " - generate code...")
	tNamespaces = {}
	
	for _,tok in ipairs(lToken1) do
		if tok[asm.TYPE] == asm.FNAME then
			local mem = pdp13.get_nvm(pos)
			local _, _, name = pdp13.path.splitpath(mem, tok[asm.STRING])
			local s = pdp13.path.splitext(name)
			tNamespaces[s] = true
		end
	end
	
	asm.section = asm.CODE
	local lToken2 = {}
	for _,tok in ipairs(lToken1) do
		local ttype, lineno, text = tok[asm.TYPE], tok[asm.LINENO], tok[asm.STRING]
		asm.lineno = lineno
		
		if text == ".data" then
			--print("trigger")
		end
		text = address_label(pos, text)
		text = section(pos, text)
		text = org_directive(pos, text)
		asm.type = asm.section -- default type
		
		if text == "" then
			-- nothing
		elseif ttype == asm.CODE then
			if asm.section == asm.CODESEC then
				decode_code(pos, lToken2, lineno, text)
			elseif asm.section == asm.DATASEC then
				decode_data(pos, lToken2, lineno, text)
			elseif asm.section == asm.TEXTSEC then
				decode_text(pos, lToken2, lineno, text)
			elseif asm.section == asm.CTEXTSEC then
				decode_ctext(pos, lToken2, lineno, text)
			end
		elseif ttype == asm.FNAME then
			asm.section = asm.CODESEC
			asm.fname = text
			local mem = pdp13.get_nvm(pos)
			local _, _, name = pdp13.path.splitpath(mem, tok[asm.STRING])
			asm.namespace = pdp13.path.splitext(name)
			table.insert(lToken2, {asm.FILENAME, asm.fname})
		elseif ttype == asm.EOF then
			asm.fname = text
			local mem = pdp13.get_nvm(pos)
			local _, _, name = pdp13.path.splitpath(mem, tok[asm.STRING])
			asm.namespace = pdp13.path.splitext(name)
			table.insert(lToken2, {asm.EOFILE, asm.fname})
		end
	end
	return lToken2
end

local function sys_asm_pass2(pos, address, val1, val2)
	local mem = pdp13.get_mem(pos)
	mem.asm_pass2 = asm.pass2(pos, mem.asm_pass1)
	if mem.asm_pass2 then
		return 1
	end
	return 0
end

pdp13.register_SystemHandler(0x201, sys_asm_pass2)

return asm
