--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 CPU

]]--


-- for lazy programmers
local M = minetest.get_meta

local VM13_OK       = 0  -- run to the end
local VM13_DELAY    = 1  -- one cycle pause
local VM13_IN       = 2  -- input command
local VM13_OUT      = 3  -- output command
local VM13_SYS      = 4  -- system call
local VM13_HALT     = 5  -- CPU halt
local VM13_ERROR    = 6  -- invalid call
local VM13_STOP     = 7  -- speudo stopped state

local UPD_COUNT   = 20

local ActionHandlers = {
	[VM13_IN] = {}
	[VM13_OUT] = {}
	[VM13_SYS] = {}
	[VM13_HALT] = {}
	[VM13_ERROR] = {}
]

local function leds(address, data)
	local lLed = {}
	for i = 16,1,-1 do
		if pdp13lib.testbit(address, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",1.6;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if pdp13lib.testbit(data, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",3.0;0.4,0.4;pdp13_led_form.png]"
		end
	end
	return table.concat(lLed, "")
end

local function vm_state(state)
	if state == VM13_STOP then return ""end
	if state == VM13_OK   then return "image[2.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if state == VM13_IN   then return "image[4.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if state == VM13_OUT  then return "image[4.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if state == VM13_HALT then return "image[6.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if state == VM13_SYS  then return "image[8.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	return ""
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function formspec(mem, cpu, last)
	local sLED
	if last == true then
		sLED = leds(cpu.l_addr, cpu.l_data)
	elseif last == false then
		sLED = leds(cpu.PC, cpu.mem0)
	else
		sLED = leds(0, 0)
	end
	mem.state = mem.state or VM13_STOP
	local state = vm_state(mem.state)
	local update = (mem.upd_cnt and mem.upd_cnt > 1 and mem.upd_cnt) or "update"
	return "size[10,7.7]"..
		"background[-0.1,-0.2;10.2,5.6;pdp13_cpu_form.png]"..
		sLED..
		state..
		"label[5.1,0.82;ADDRESS]"..
		"label[5.1,2.22;DATA]"..
		
		"label[2.5,0.4; run]"..
		"label[4.5,0.4; i/o]"..
		"label[6.5,0.4; halt]"..
		"label[8.5,0.4; sys]"..
		
		"button[0,5.4;1.8,1;start;start]"..
		"button[1.9,5.4;1.8,1;stop;stop]"..
		
		"button[0,6.3;1.8,1;step;step]"..
		"button[1.9,6.3;1.8,1;reset;reset]"..
		
		"button[0,7.2;1.8,1;examine;examine]"..
		"button[1.9,7.2;1.8,1;update;"..update.."]"..
		
		"background[3.8,5.6;6.1,1.2;pdp13_form_mask.png]"..
		
		"label[3.8,6.8;l <addr> (load)     d <val> (deposite)]"..
		
		"field[4,7.6;6.3,0.8;command;;]"..
		"field_close_on_enter[command;false]"
end

local function ret_code_handling(vm, mem, res)
	mem.state = res
	if res == VM13_DELAY then
		mem.state = VM13_OK
	elseif res == VM13_IN then
		local evt = pdp13lib.get_event(vm, res)
		if InHandler[evt.addr] then
			InHandler[evt.addr](vm, evt)
		end
	elseif res == VM13_OUT then
		local evt = pdp13lib.get_event(vm, res)
		if OutHandler[evt.addr] then
			OutHandler[evt.addr](vm, evt)
		end
	elseif res == VM13_SYS then
		local evt = pdp13lib.get_event(vm, res)
		if SysHandler[evt.addr] then
			SysHandler[evt.addr](vm, evt)
		end
	end	
end	

local function update_formspec(pos, mem, vm, last)
	if vm then
		local cpu = pdp13lib.get_cpu_reg(vm)
		if cpu then
			M(pos):set_string("formspec", formspec(mem, cpu, last))
			return
		end
	end
	M(pos):set_string("formspec", formspec(mem))
end	

function pdp13.call_cpu(pos, vm, cycles)
	local mem = tubelib2.get_mem(pos)
	local res = pdp13lib.run(vm, cycles)
	if res > VM13_DELAY then
		ret_code_handling(vm, mem, res)
	end
	if mem.upd_cnt then
		update_formspec(pos, mem, vm, false)
		mem.upd_cnt = mem.upd_cnt - 1
		if mem.upd_cnt < 0 then
			mem.upd_cnt = nil
		end
	end
end


local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	local owner = M(pos):get_string("owner")
	local vm = pdp13.vm_get(owner, pos)
	
	if mem.started then
		if fields.stop then
			pdp13.vm_suspend(owner, pos)
			pdp13.remove_from_owner_list(owner, pos)
			mem.state = VM13_STOP
			mem.started = false
			update_formspec(pos, mem, vm, false)
		elseif fields.update then
			mem.upd_cnt = UPD_COUNT
			update_formspec(pos, mem, vm, false)
		end
	else -- stopped
		if fields.key_enter == "true" then
			local cmnd, val = string.match (fields.command, "^([rld]) +([0-9a-fA-F]+)$")
			if cmnd == "l" then 
				mem.state = VM13_STOP
				pdp13lib.loadaddr(vm, tonumber(val, 16))
				update_formspec(pos, mem, vm, false)
			elseif cmnd == "d" then
				mem.state = VM13_STOP
				pdp13lib.deposit(vm, tonumber(val, 16)) 
				update_formspec(pos, mem, vm, true)
			elseif cmnd == "r" then 
				print(dump(pdp13lib.get_cpu_reg(vm)))
			end 
		elseif fields.start and mem.state ~= VM13_HALT then
			pdp13.vm_store(owner, pos)
			pdp13.vm_resume(owner, pos)
			pdp13.add_to_owner_list(owner, pos)
			mem.started = true
			mem.state = VM13_OK
			mem.upd_cnt = UPD_COUNT
			update_formspec(pos, mem, vm)
		elseif fields.examine then
			pdp13lib.examine(vm)
			update_formspec(pos, mem, vm, true)
		elseif fields.step and mem.state ~= VM13_HALT then
			local res, _ = pdp13lib.run(vm, 1) 
			if res == VM13_OK then res = VM13_STOP end
			ret_code_handling(vm, mem, res)
			update_formspec(pos, mem, vm, false)
		elseif fields.reset then
			mem.state = VM13_STOP
			pdp13lib.loadaddr(vm, 0) 
			update_formspec(pos, mem, vm, false)
		end
	end
end

local function pdp13_command(pos, cmnd)
	if cmnd == "on" then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		pdp13.vm_create(owner, pos)
		mem.started = false
		mem.state = VM13_STOP
		swap_node(pos, "pdp13:cpu1_on")
	elseif cmnd == "off" then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		if mem.started then
			pdp13.vm_suspend(owner, pos)
		end
		mem.started = false
		mem.state = VM13_STOP
		pdp13.remove_from_owner_list(owner, pos)
		pdp13.vm_destroy(owner, pos)
		swap_node(pos, "pdp13:cpu1")
		update_formspec(pos, mem)
	end
end

minetest.register_node("pdp13:cpu1", {
	description = "PDP-13 CPU",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_cpu.png^pdp13_frame.png^pdp13_frame_top.png",
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local mem = tubelib2.init_mem(pos)
		M(pos):set_string("owner", placer:get_player_name())
		update_formspec(pos, mem)
	end,
	pdp13_command = pdp13_command,
	after_dig_node = function(pos, oldnode)
		local owner = M(pos):get_string("owner")
		pdp13.vm_destroy(owner, pos)
	end,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("pdp13:cpu1_on", {
	description = "PDP-13 CPU",
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		{
			image = "pdp13_frame4.png^pdp13_cpu4.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.6,
			},
		},
	},
	on_receive_fields = on_receive_fields,
	pdp13_command = pdp13_command,
	paramtype2 = "facedir",
	diggable = false,
	groups = {not_in_creative_inventory=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

