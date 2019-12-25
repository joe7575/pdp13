--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 VM16 Opcodes

]]--

--
-- OP-codes
--
pdp13.VM13Opcodes = {[0] =
    "dly:NUM:-", "sys:NUM:-", "rst:NUM:-", "res:-:-",
	"jump:ADR:-", "call:ADR:-", "ret:-:-", "halt:-:-",
    "move:DST:SRC", "xchg:DST:DST", "inc:DST:-", "dec:DST:-",
    "add:DST:SRC", "sub:DST:SRC", "mul:DST:SRC", "div:DST:SRC",
    "and:DST:SRC", "or:DST:SRC", "xor:DST:SRC", "not:DST:-",
    "bnze:DST:ADR", "bze:DST:ADR", "bpos:DST:ADR", "bneg:DST:ADR",
    "in:DST:CNST", "out:CNST:SRC", "push:SRC:-", "pop:DST:-", 
    "swap:DST:-", "dbnz:DST:ADR", "mod:DST:SRC",
	"shl:DST:SRC", "shr:DST:SRC", 
}

--
-- Operands
--
pdp13.VM13Operands = {[0] =
    "A", "B", "C", "D", "X", "Y", "PC", "SP",
    "[X]", "[Y]", "[X]+", "[Y]+", "#0", "#1", "-", "-", 
    "IMM", "IND", "REL", "[SP+n]",
}

