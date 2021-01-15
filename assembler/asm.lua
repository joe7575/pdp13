--[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Assembler
]]--

local MP = minetest.get_modpath("pdp13")
local asm = {}

-- Pass1: type
asm.FNAME   = 1
asm.CODE    = 2
asm.COMMENT = 3
asm.EOF     = 4

-- Pass1: token elements
asm.TYPE   = 1
asm.LINENO = 2
asm.STRING = 3

-- Pass2: token elements
asm.DATASEC    = 1
asm.CODESEC    = 2
asm.TEXTSEC    = 3
asm.CTEXTSEC   = 4
asm.CODESYMSEC = 5
asm.FILENAME   = 6
asm.EOFILE     = 7

assert(loadfile(MP .. "/assembler/pass1.lua"))(asm)
assert(loadfile(MP .. "/assembler/pass2.lua"))(asm)
assert(loadfile(MP .. "/assembler/pass3.lua"))(asm)

function asm.outp(pos, s)
	pdp13.push_pipe(pos, {s})
end

function asm.err_msg(pos, err)
	if not asm.error then
		asm.outp(pos, string.format("Err: %s(%u): %s!", asm.fname, asm.lineno or 0, err))
		asm.error = true
	end
end


function pdp13.assembler(pos, fname)
	asm.outp(pos, "VM16 ASSEMBLER v1.3.0 (c) 2019-2021 by Joe")
	
	asm.address = 0
	asm.lineno = 0
	asm.fname = fname
	asm.type = asm.CODE
	asm.section = asm.CODESEC
	
	if pdp13.path.has_ext(fname, "asm") then
		local lToken1 = asm.pass1(pos, fname)
		local lToken2 = asm.pass2(pos, lToken1)
		if not asm.error then
			local first, last, size = asm.pass3(pos, lToken2, fname)
			if not asm.error then
				asm.outp(pos, "Code start address: " .. string.format("$%04X", first))
				asm.outp(pos, "Last used address:  " .. string.format("$%04X", last))
				asm.outp(pos, "Code size [words]:  " .. string.format("$%04X", size))
			end
		end
	else
		asm.err_msg(pos, "Invalid file")
	end
	return true
end

local function sys_asm(pos, address, val1, val2)
	local fname = vm16.read_ascii(pos, val1, pdp13.MAX_LINE_LEN)
	return pdp13.assembler(pos, fname) and 1 or 0
end

pdp13.register_SystemHandler(0x200, sys_asm)
