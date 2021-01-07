--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Install Fake Tapes

]]--

pdp13.tape.register_tape("pdp13:tape_system1", "System Tape 1", [[
J/OS System Tape 1: Basis OS

Use the J/OS Installation Tape to install J/OS.
]], [[:200000100000000
:00000FF]], true)

pdp13.tape.register_tape("pdp13:tape_system2", "System Tape 2", [[
J/OS System Tape 2: ASM and stdlib

Use the J/OS Installation Tape to install J/OS.
]], [[:200000100000000
:00000FF]], true)

pdp13.tape.register_tape("pdp13:tape_system3", "System Tape 3", [[
J/OS System Tape 3: Example Files

Use the J/OS Installation Tape to install J/OS.
]], [[:200000100000000
:00000FF]], true)

