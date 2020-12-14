--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
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

minetest.register_craftitem("pdp13:rom", {
	description = "PDP-13 Monitor ROM",
	inventory_image = "pdp13_rom.png",
})

minetest.register_craftitem("pdp13:ic1", {
	description = "PDP-13 IC small",
	inventory_image = "pdp13_ic1.png",
})

minetest.register_craftitem("pdp13:ic2", {
	description = "PDP-13 IC large",
	inventory_image = "pdp13_ic2.png",
})

techage.recipes.add("ta3_electronic_fab", {
	output = "pdp13:ic1",
	input = {
		"basic_materials:ic 2", 
		"basic_materials:silicon", "techage:usmium_nuggets 1"
	}
})

techage.recipes.add("ta3_electronic_fab", {
	output = "pdp13:ram4k",
	input = {
		"basic_materials:ic 2", 
		"basic_materials:plastic_sheet 1", "techage:usmium_nuggets 1"
	}
})

techage.recipes.add("ta3_electronic_fab", {
	output = "pdp13:ic2",
	input = {
		"pdp13:ic1 8", 
	}
})

techage.recipes.add("ta3_electronic_fab", {
	output = "pdp13:ram8k",
	input = {
		"pdp13:ram4k 2", 
	}
})