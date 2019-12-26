--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Test ROMs

]]--

minetest.register_craftitem("pdp13:boot_rom", {
	description = "PDP-13 Monitor ROM 1000",
	inventory_image = "pdp13_rom4k.png",
	stack_max = 1,
	pdp13_code = {
		0x208C, 0x658D, 0x600C, 0x5412, 0xFFFD, 0x600D, 0x2140, 0x1240, 
		0xFFF9
	}
})

minetest.register_craftitem("pdp13:lamp_rom", {
	description = "PDP-13 Lamp ROM 2000 (2->3)",
	inventory_image = "pdp13_rom4k.png",
	stack_max = 1,
	pdp13_code = {
		0x6010, 0x0010, 0x6600, 0x0018, 0x1240, 0xFFFA
	}
})
