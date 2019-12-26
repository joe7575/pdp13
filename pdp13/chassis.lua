--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Extension chassis

]]--

-- for lazy programmers
local M = minetest.get_meta
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local get_tbl = function(meta,key) return minetest.deserialize(meta:get_string(key)) or {} end

local ValidExtensions= {
	["pdp13:rom4k_burned"] = {type = "rom", size = 1},
	["pdp13:boot_rom"] = {type = "rom", size = 1},
	["pdp13:lamp_rom"] = {type = "rom", size = 1},
	["pdp13:ram4k"] = {type = "ram", size = 1},
	["pdp13:ram8k"] = {type = "ram", size = 2},
	--[""] = true,
}

local function formspec()
	return "size[8,8]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"label[0.3,0;1]label[1.3,0;2]label[2.3,0;3]label[3.3,0;4]"..
		"label[4.3,0;5]label[5.3,0;6]label[6.3,0;7]label[7.3,0;8]"..
		"list[context;main;0,0.5;8,2;]"..
		"label[0.3,2.5;9]label[1.2,2.5;10]label[2.2,2.5;11]label[3.2,2.5;12]"..
		"label[4.2,2.5;13]label[5.2,2.5;14]label[6.2,2.5;15]label[7.2,2.5;16]"..
		"list[current_player;main;0,4;8,4;]"..
		"listring[context;main]"..
		"listring[current_player;main]"
end

local function read_rom(pos, slot)
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return nil end
	local stack = inv:get_stack("main", slot)
	local name = stack:get_name()
	local count = stack:get_count()
	if name == "pdp13:rom4k_burned" then
		local meta = stack:get_meta()
		return get_tbl(meta, "code")
	end
	if ValidExtensions[name] then
		local ndef = minetest.registered_craftitems[name]
		if ndef.pdp13_code then
			return ndef.pdp13_code
		end
	end
end

local function get_extensions(pos)
	local tbl = {}
	local inv = M(pos):get_inventory()
	if inv:is_empty("main") then return tbl end
	local addr = 4096
	for slot = 1,16 do
		local stack = inv:get_stack("main", slot)
		local name = stack:get_name()
		if ValidExtensions[name] then
			for i = 1, ValidExtensions[name].size do
				tbl[#tbl+1] = table.copy(ValidExtensions[name])
				tbl[#tbl].addr = addr
				if ValidExtensions[name].type == "rom" then
					tbl[#tbl].code = read_rom(pos, slot)
				end
				addr = addr + 4096
				print("get_extensions", tbl[#tbl].addr, tbl[#tbl].type, dump(tbl[#tbl].code))
			end
		end
	end	
	return tbl
end	

local function set_running(pos, running)
	M(pos):set_int("power", running and 1 or 0)
end	

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if M(pos):get_int("power") == 1 then
		return 0
	end
	local name = stack:get_name()
	local count = stack:get_count()
	if not ValidExtensions[name] or count ~= 1 then
		return 0
	end
	
	local inv = M(pos):get_inventory()
	local list = inv:get_list("main")
	if list[index]:get_count() == 0 then
		return 1
	end
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if M(pos):get_int("power") == 1 then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if M(pos):get_int("power") == 1 then
		return 0
	end
	local inv = M(pos):get_inventory()
	local list = inv:get_list("main")
	if list[to_index]:get_count() == 0 then
		return 1
	end
	return 0
end

minetest.register_node("pdp13:chassis", {
	description = "PDP-13 Extension Chassis",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_chassis.png^pdp13_frame.png",
	},
	on_construct = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 16)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		M(pos):set_string("formspec", formspec())
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	pdp13_read_rom = read_rom,
	pdp13_get_extensions = get_extensions,
	pdp13_set_running = set_running,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("pdp13:chassis_top", {
	description = "PDP-13 Extension Chassis",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_chassis.png^pdp13_frame_top.png",
	},
	on_construct = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 16)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		M(pos):set_string("formspec", formspec())
	end,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	pdp13_read_rom = read_rom,
	pdp13_get_extensions = get_extensions,
	pdp13_set_running = set_running,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

