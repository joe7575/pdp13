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

-- Terminal
pdp13.CLS          = 0x10
pdp13.PRINT_CHAT   = 0x11
pdp13.PRINT_NUM    = 0x12
pdp13.PRINT_STR    = 0x13
pdp13.PRINT_STRLN  = 0x14
pdp13.UPD_SCREEN   = 0x15
pdp13.START_ED     = 0x16
pdp13.INPUT        = 0x17
pdp13.PRINT_SM     = 0x18
pdp13.FLUSH        = 0x19
pdp13.PROMPT       = 0x1A

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
pdp13.CHANGE_DIR   = 0x5B

pdp13.COLD_START   = 0x70
pdp13.WARM_START   = 0x71
pdp13.LOAD_H16     = 0x72
pdp13.ROM_SIZE     = 0x73
pdp13.CURR_DRIVE   = 0x74
pdp13.LOAD_COM     = 0x75
pdp13.H16_SIZE     = 0x76
pdp13.STORE_COM    = 0x77

pdp13.TAPE_NUM     = 1
pdp13.HDD_NUM      = 2
pdp13.WARTSTART_ADDR = 2

pdp13.WR  = 119  -- 'w'
pdp13.RD  = 114  -- 'r'

-- COM
pdp13.PARAM_BUFF = 0x00c0
pdp13.START_ADDR = 0x0100
