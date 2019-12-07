#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# PDP-13 Assembler v1.0
# Copyright (C) 2019 Joe <iauit@gmx.de>
#
# This file is part of PDP-13.

# PDP-13 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# PDP-13 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with PDP-13.  If not, see <https://www.gnu.org/licenses/>.

#
# OP-codes
#
Opcodes = [
    "nop:-:-", "halt:-:-", "call:-:ADR", "ret:-:-",
    "move:DST:SRC", "jump:-:ADR", "inc:DST:-", "dec:DST:-",
    "add:DST:SRC", "sub:DST:SRC", "mul:DST:SRC", "div:DST:SRC",
    "and:DST:SRC", "or:DST:SRC", "xor:DST:SRC", "not:DST:SRC",
    "bnze:REG:ADR", "bze:REG:ADR", "bpos:REG:ADR", "bneg:REG:ADR",
    "in:DST:CNST", "out:CNST:SRC", "push:SRC:-", "pop:DST:-", 
    "swap:DST:-", "dbnz:REG:ADR", "dly:-:-", "sys:-:CNST"
]

JumpInst = ["call", "jump", "bnze", "bze", "bpos", "bneg", "dbnz"]

#
# Operands
#
Operands = [
    "a", "b", "c", "d", "x", "y", "pc", "sp",
    "[x]", "[y]", "[x]+", "[y]+", "#0", "#1", "-", "-", 
    "#imm", "ind", "+/-rel", "[sp+n]",
]
RegOperands = Operands[0:-4]

#
# Operand Groups
#
REG = ["a", "b", "c", "d", "x", "y", "pc", "sp"]
MEM = ["[x]", "[y]", "[x]+", "[y]+", "ind", "[sp+n]"]
ADR = ["#imm", "+/-rel", "[x]", "[y]"]
CNST = ["#0", "#1", "#imm"]
DST = REG + MEM
SRC = DST + CNST 

