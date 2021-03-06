--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 VM16 Opcodes

]]--

--
-- OP-codes
--
pdp13.VM16Opcodes = {[0] =
    "nop:-:-", "brk:CNST:-", "sys:CNST:-", "res2:CNST:-",
	"jump:ADR:-", "call:ADR:-", "ret:-:-", "halt:-:-",
    "move:DST:SRC", "xchg:DST:DST", "inc:DST:-", "dec:DST:-",
    "add:DST:SRC", "sub:DST:SRC", "mul:DST:SRC", "div:DST:SRC",
    "and:DST:SRC", "or:DST:SRC", "xor:DST:SRC", "not:DST:-",
    "bnze:DST:ADR", "bze:DST:ADR", "bpos:DST:ADR", "bneg:DST:ADR",
    "in:DST:CNST", "out:CNST:SRC", "push:SRC:-", "pop:DST:-", 
    "swap:DST:-", "dbnz:DST:ADR", "mod:DST:SRC",
	"shl:DST:SRC", "shr:DST:SRC", "addc:DST:SRC", "mulc:DST:SRC",
    "skne:SRC:SRC", "skeq:SRC:SRC", "sklt:SRC:SRC", "skgt:SRC:SRC",
}

--
-- Operands
--
pdp13.VM16Operands = {[0] =
    "A", "B", "C", "D", "X", "Y", "PC", "SP",
    "[X]", "[Y]", "[X]+", "[Y]+", "#0", "#1", "-", "-", 
    "IMM", "IND", "REL", "[SP+n]",
}

--
-- Need special operand handling
--
pdp13.JumpInst = {
	["call"] = true, ["jump"] = true, ["bnze"] = true, ["bze"] = true, 
	["bpos"] = true, ["bneg"] = true, ["dbnz"] = true}

