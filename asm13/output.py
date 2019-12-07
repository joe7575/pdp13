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

import re
import sys
import os
import pprint
import __init__ as pdp13
from instructions import *

def table_opcode():
    lOut = []
    row = [" 1,2 "]
    for offs, opnd in enumerate(Operands):
        if opnd in DST:
            row.append("%4s" % opnd)
    lOut.append(row)
    for idx, opc in enumerate(Opcodes):
        if opc.split(":")[1] not in ["-", "CNST"]:
            row = ["%-5s" % opc.split(":")[0]]
            for offs, opnd in enumerate(Operands):
                if opnd in DST:
                    key = opc.split(":")[1]
                    if opnd in globals()[key]:
                        row.append("%5X" % ((idx << 10) + (offs << 5)))
                    else:
                        row.append("  --")
        else:
            continue
        lOut.append(row)

    for idx, row in enumerate(lOut):
        print("|" + "|".join(["%-6s" % item for item in row]) + "|")
        if idx == 0:
            print("|" + "|".join(["------" for item in row]) + "|")
    ####################################################   

    print
    for idx, item in enumerate(Opcodes):
        opc = item.split(":")[0]
        if opc == "out":
            print("|  2      |      |")
            print("|---------|------|")
            for opnd in ["#0", "#1", "#imm"]:
                offs = Operands.index(opnd)
                opc = (idx << 10) + (offs << 5)
                print("|out %4s |%5X |" % (opnd, opc))
    ####################################################   

    print
    lOut = [[" 0,1 ", "  --"]]
    for idx, opc in enumerate(Opcodes):
        if opc.split(":")[1] == "-":
            row = ["%-5s" % opc.split(":")[0]]
            row.append("%5X" % (idx << 10))
            lOut.append(row)
 
    for idx, row in enumerate(lOut):
        print("|" + "|".join(["%-6s" % item for item in row]) + "|")
        if idx == 0:
            print("|" + "|".join(["------" for item in row]) + "|")
    ####################################################   

    print
    l = ["%4s" % item for item in Operands[:12]]
    print("|" + "|".join(["%-6s" % item for item in l]) + "|")
    print("|" + "|".join(["------" for item in Operands[:12]]) + "|")
    print("|" + "|".join(["%4X  " % idx for idx in range(0, len(Operands[:12]))]) + "|")
    print
    l = ["%4s" % item for item in Operands[12:]]
    print("|" + "|".join(["%-6s" % item for item in l]) + "|")
    print("|" + "|".join(["------" for item in Operands[12:]]) + "|")
    print("|" + "|".join(["%4X  " % (idx + 12) for idx in range(0, len(Operands[12:]))]) + "|")

table_opcode()
