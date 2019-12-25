--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 4K/8K RAM

]]--

local MAX_SIZE = 80


minetest.register_craftitem("pdp13:ram4k", {
	description = "PDP-13 RAM 4K",
	inventory_image = "pdp13_ram4k.png",
})

minetest.register_craftitem("pdp13:ram8k", {
	description = "PDP-13 RAM 8K",
	inventory_image = "pdp13_ram8k.png",
})

