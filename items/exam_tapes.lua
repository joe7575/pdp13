--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Exam Tapes

]]--

pdp13.tape.register_tape("pdp13:tape_monitor", "Exam1: Monitor Program", [[
PDP13 Monitor Program Code

Use this tape to produce a PDP-13 Monitor ROM chip
on the Fab.
]], [[:200000100000000
:00000FF]], true)

pdp13.tape.register_tape("pdp13:tape_bios", "Exam2: BIOS Program", [[
PDP13 BIOS Program Code

Use this tape to produce a PDP-13 BIOS ROM chip
on the Fab.
]], [[:200000100000000
:00000FF]], true)

-- Exam3: Add OS tapes to the tape chest

pdp13.tape.register_tape("pdp13:tape_hdd", "Exam4: Hard Disk Program", [[
PDP13 Hard Disk Program Code

Use this tape to produce a PDP-13 Hard Disk ROM chip
on the Fab.
]], [[:200000100000000
:00000FF]], true)

pdp13.tape.register_tape("pdp13:tape_comm", "Exam5: COMM Program", [[
PDP13 COMM Program Code

Use this tape to produce a PDP-13 COMM ROM chip
on the Fab.
]], [[:200000100000000
:00000FF]], true)
