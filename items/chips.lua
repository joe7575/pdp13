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

minetest.register_craftitem("pdp13:ram16k", {
	description = "PDP-13 RAM 16K",
	inventory_image = "pdp13_ram16k.png",
})

minetest.register_craftitem("pdp13:mon_rom", {
	description = "PDP-13 Monitor ROM",
	inventory_image = "pdp13_rom.png",
})

minetest.register_craftitem("pdp13:bios_rom", {
	description = "PDP-13 BIOS ROM",
	inventory_image = "pdp13_rom.png",
})

minetest.register_craftitem("pdp13:comm_rom", {
	description = "PDP-13 COMM ROM",
	inventory_image = "pdp13_rom.png",
})

minetest.register_craftitem("pdp13:disk_rom", {
	description = "PDP-13 Disk ROM",
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

if minetest.global_exists("techage") then

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:ic1 1",
		input = {
			"basic_materials:ic 2", 
			"basic_materials:silicon 1", "techage:usmium_nuggets 1"
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:ram4k 1",
		input = {
			"basic_materials:ic 2", 
			"basic_materials:plastic_sheet 1", "techage:usmium_nuggets 1"
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:ic2 1",
		input = {
			"pdp13:ic1 8", 
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:ram8k 1",
		input = {
			"pdp13:ram4k 2", 
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:mon_rom 1",
		input = {
			"pdp13:ic1 8", 
			"pdp13:tape_monitor 1",
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:bios_rom 1",
		input = {
			"pdp13:ic1 8", 
			"pdp13:tape_bios 1",
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:disk_rom 1",
		input = {
			"pdp13:ic1 8", 
			"pdp13:tape_hdd 1",
		}
	})

	techage.recipes.add("ta3_electronic_fab", {
		output = "pdp13:comm_rom 1",
		input = {
			"pdp13:ic1 8", 
			"pdp13:tape_comm 1",
		}
	})

else

	minetest.register_craft({
		output = "pdp13:ic1 4",
		recipe = {
			{"basic_materials:ic", "basic_materials:ic", ""},
			{"basic_materials:silicon", "basic_materials:energy_crystal_simple", ""},
			{"basic_materials:plastic_sheet", "basic_materials:plastic_sheet", ""},
		}
	})

	minetest.register_craft({
		output = "pdp13:ram4k",
		recipe = {
			{"basic_materials:ic", "basic_materials:ic", ""},
			{"basic_materials:plastic_sheet", "basic_materials:energy_crystal_simple", ""},
			{"", "", ""},
		}
	})

	minetest.register_craft({
		output = "pdp13:ic2",
		recipe = {
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"pdp13:ic1", "", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
		}
	})

	minetest.register_craft({
		output = "pdp13:ram8k",
		recipe = {
			{"pdp13:ram4k", "", ""},
			{"pdp13:ram4k", "", ""},
			{"", "", ""},
		}
	})

	minetest.register_craft({
		output = "pdp13:mon_rom",
		recipe = {
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:tape_monitor", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
		}
	})

	minetest.register_craft({
		output = "pdp13:bios_rom",
		recipe = {
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:tape_bios", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
		}
	})

	minetest.register_craft({
		output = "pdp13:disk_rom",
		recipe = {
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:tape_hdd", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
		}
	})
	
	minetest.register_craft({
		output = "pdp13:comm_rom",
		recipe = {
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:tape_comm", "pdp13:ic1"},
			{"pdp13:ic1", "pdp13:ic1", "pdp13:ic1"},
		}
	})

end

minetest.register_alias("pdp13:os_rom", "pdp13:bios_rom")
