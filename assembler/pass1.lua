--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Assembler pass1 (scanner)
	- remove comments
    - expand macros
    - handle include files
    - provide a list with {type, lineno, string}
]]--

local asm = ...
local tDirs = {}  -- search paths
local tMacros = {}
local lFnames = {}

local function startswith(s, keyword)
   return string.sub(s, 1, string.len(keyword)) == keyword
end

local strfind = string.find
local strsub = string.sub
local tinsert = table.insert

local function strsplit(text)
   local list = {}
   local pos = 1
   
   while true do
      local first, last = strfind(text, "\n", pos)
      if first then -- found?
         tinsert(list, strsub(text, pos, first-1))
         pos = last+1
      else
         tinsert(list, strsub(text, pos))
         break
      end
   end
   return list
end

local function expand_macro(pos, lToken, name, params)
	local num_param = #params
	if num_param ~= tMacros[name][1] then
		asm.err_msg(pos, "Invalid macro parameter(s)")
		return false
	end
	for idx, item in ipairs(tMacros[name]) do
		if idx > 1 then
			if num_param > 0 then item = item:gsub("%%1", params[1]) end
			if num_param > 1 then item = item:gsub("%%2", params[2]) end
			if num_param > 2 then item = item:gsub("%%3", params[3]) end
			if num_param > 3 then item = item:gsub("%%4", params[4]) end
			if num_param > 4 then item = item:gsub("%%5", params[5]) end
			if num_param > 5 then item = item:gsub("%%6", params[6]) end
			if num_param > 6 then item = item:gsub("%%7", params[7]) end
			if num_param > 7 then item = item:gsub("%%8", params[8]) end
			if num_param > 8 then item = item:gsub("%%9", params[9]) end
			table.insert(lToken, {asm.CODE, asm.lineno, item})
		end
	end
	return true
end
	
-- Read ASM file with all include files.
-- Function is called recursively to handle includes.
-- Returns a list with {type, lineno, string}
local function scanner(pos, lToken, fname, call_count)
	local path = pdp13.get_asm_path(pos, fname)
	if not path then
		asm.err_msg(pos, "Can't find file")
		return
	end
	-- already included
	if path == true then 
		return true
	end
	
	if call_count == 1 then
		asm.outp(pos, " - read " .. path .. "...")
	else
		asm.outp(pos, " - import " .. path .. "...")
	end
	
	call_count = call_count + 1
	if call_count > 10 then
		asm.err_msg(pos, "Recursive include")
		return
	end
		
	asm.fname = fname
	table.insert(lToken, {asm.FNAME, 0, fname})
	
	local text = pdp13.read_file(pos, path)
	if not vm16.is_ascii(text) then
		asm.err_msg(pos, "Invalid file format")
		return
	end
		
	local macro_name = false
	for lineno, line in ipairs(strsplit(text)) do repeat
		local _, _, s = line:find("(.+);")
		line = string.trim(s or line)
		if string.byte(line, 1) == 59 then -- ';'
			do break end -- continue
		end
		if line == "" then
			do break end -- continue
		end
		
		asm.lineno = lineno
		-- handle include files
		_, _, s = line:find('^%$include +"(.-)"')
		if s then
			if not scanner(pos, lToken, s, call_count) then
				return
			end
			table.insert(lToken, {asm.EOF, lineno, fname})
			asm.fname = fname
			do break end -- continue
		end
		
		-- end of macro definition
		if macro_name and startswith(line, "$endmacro") then
			macro_name = false
		-- code of macro definition
		elseif macro_name then
			table.insert(tMacros[macro_name], line)
		-- start of macro definition
		elseif startswith(line, "$macro") then
			local _, _, name, num_param = 
					line:find('^%$macro +([A-Za-z_][A-Za-z_0-9%.]+) *([0-9]?)$')
			if name then
				macro_name = name
				num_param = tonumber(num_param or "0")
				tMacros[macro_name] = {num_param}
				table.insert(lToken, {asm.COMMENT, lineno, "; " .. line})
			else
				asm.err_msg(pos, "Invalid macro syntax")
				return
			end
		else
			-- expand macro 
			local _, _, name, params = line:find('^([A-Za-z_][A-Za-z_0-9%.]+) *(.*)$')
			if name and tMacros[name] then
				params = string.split(params, " ")
				if expand_macro(pos, lToken, name, params) then
					do break end -- continue
				else
					return
				end
			end
			table.insert(lToken, {asm.CODE, lineno, line})
		end
	until true end	
	return true
end

function asm.pass1(pos, fname)
	tDirs = {}
	tMacros = {}
	lFnames = {}
	local lToken = {}
	if scanner(pos, lToken, fname, 1) then
		return lToken
	end
	return {}
end
