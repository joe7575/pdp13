--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Common OS Defines

]]--

pdp13.MAX_FNAME_LEN    = 12
pdp13.MAX_LINE_LEN     = 64

-- size translation
pdp13.tROM_SIZE = {[0] = 0, [1] = 8, [2] = 16, [3] = 32}

-- SYS File System
pdp13.FOPEN        = 0x50
pdp13.FCLOSE       = 0x51
pdp13.READ_FILE    = 0x52
pdp13.READ_LINE    = 0x53
pdp13.WRITE_FILE   = 0x54
pdp13.WRITE_LINE   = 0x55
pdp13.FILE_SIZE    = 0x56
pdp13.LIST_FILES   = 0x57
pdp13.REMOVE_FILES = 0x58
pdp13.COPY_FILE    = 0x59
pdp13.MOVE_FILE    = 0x5A

pdp13.COLD_START   = 0x70
pdp13.WARM_START   = 0x71
pdp13.LOAD_H16     = 0x72
pdp13.ROM_SIZE     = 0x73

pdp13.TAPE_NUM     = 1
pdp13.HDD_NUM      = 2