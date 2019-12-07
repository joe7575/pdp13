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
local get_tbl = function(pos,key)      return minetest.deserialize(M(pos):get_string(key)) or {} end
local set_tbl = function(pos,key,tbl)  M(pos):set_string(key, minetest.serialize(tbl)) end

local VM13_OK       = 0  -- run to the end
local VM13_DELAY    = 1  -- one cycle pause
local VM13_IN       = 2  -- input command
local VM13_OUT      = 3  -- output command
local VM13_SYS      = 4  -- system call
local VM13_HALT     = 5  -- CPU halt
local VM13_ERROR    = 6  -- invalid call
local VM13_STOP     = 7  -- speudo stopped state

local UPD_COUNT  = 20
local CREDIT     = 100

local ActionHandlers = {}

-- Action (input/output):
--   u16_resp = output(pos, u3_offs, u16_data) -- return 0/1
--   u16_resp = input(pos, u3_offs)
local function register_action(pos, io_num, io_type, io_pos, credit, func)
	print("ActionHandlers: io_num, io_type, credit, func", io_num, io_type, credit, func)
	local hash = minetest.hash_node_position(pos)
	ActionHandlers[hash] = ActionHandlers[hash] or {}
	ActionHandlers[hash][io_num] = ActionHandlers[hash][io_num] or {}
	ActionHandlers[hash][io_num][io_type] = {pos = io_pos, func = func, credit = credit}
end

function pdp13.update_action_list(pos)
	print("update_action_list")
	local addr_tbl = get_tbl(pos, "addr_tbl")
	for io_num,number in ipairs(addr_tbl) do
		local info = techage.get_node_info(number)
		if info then
			local resp = techage.send_single(0, number, "pdp13_input")
			if resp then
				register_action(pos, io_num, VM13_IN, info.pos, resp.credit, resp.func)
			end
			resp = techage.send_single(0, number, "pdp13_output")
			if resp then
				register_action(pos, io_num, VM13_OUT, info.pos, resp.credit, resp.func)
			end
		elseif number ~= "" then
			print("pdp13.update_action_list: invalid node number", number)
		end
	end
end

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

local function hex8(u8)
	return string.format("%02X", u8)
end

local function formspec1(mem, cpu, last)
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
		"tabheader[0,0;tab;CPU,I/O;1;;true]"..
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

local function formspec2(pos)
	local tbl = get_tbl(pos, "addr_tbl")
	print(dump(tbl))
	local t = {"label[0.0,0;No]label[0.8,0;I/O Addr]label[2.2,0;Number]label[3.5,0;Info]",
	           "label[5.2,0;No]label[6.0,0;I/O Addr]label[7.4,0;Number]label[8.7,0;Info]"}
	for i = 1,16 do
		local ypos = 0.1 + i * 0.4
		local addr1 = hex8(((i-1) * 16) + 0).." - "..hex8(((i-1) * 16 + 7) + 0)
		local addr2 = hex8(((i-1) * 16) + 8).." - "..hex8(((i-1) * 16 + 7) + 8)
		local num1 = tbl[(i-1)*2 + 1] or ""
		local num2 = tbl[(i-1)*2 + 2] or ""
		local info1 = "IN(2)"
		local info2 = "OUT(1)"
		local tooltip1 = "wois ned"
		local tooltip2 = "wois ned"
		
		-- label
		t[#t+1] = "label[0.0,"..ypos..";"..((i-1)*2 + 1).."]"
		t[#t+1] = "label[5.2,"..ypos..";"..((i-1)*2 + 2).."]"		
		-- I/O Addr
		t[#t+1] = "label[0.8,"..ypos..";"..addr1.."]"
		t[#t+1] = "label[6.0,"..ypos..";"..addr2.."]"
		-- node number
		t[#t+1] = "label[2.2,"..ypos..";"..num1.."]"
		t[#t+1] = "label[7.4,"..ypos..";"..num2.."]"
		-- Info
		t[#t+1] = "label[3.5,"..ypos..";"..info1.."]"		
		t[#t+1] = "label[8.7,"..ypos..";"..info2.."]"		
		-- tooltip
		t[#t+1] = "tooltip[3.5,"..ypos..";2,0.5;"..tooltip1.."]"
		t[#t+1] = "tooltip[8.7,"..ypos..";2,0.5;"..tooltip2.."]"
	end	
		
	return "size[10,7.7]"..
		"tabheader[0,0;tab;CPU,I/O;2;;true]"..
		"background[0.0,0.6;4.8,6.4;pdp13_form_mask_lila.png]"..
		"background[5.2,0.6;4.8,6.4;pdp13_form_mask_lila.png]"..
		table.concat(t, "")..
		"label[0,7.2;Set node number:\ne.g. 1=1234]"..
		"field[4,7.6;6.3,0.8;address;;]"..
		"field_close_on_enter[address;false]"
end

local function action_handling(pos, vm, resp)
	local evt = pdp13lib.get_event(vm, resp)
	local hash = minetest.hash_node_position(pos)
	local num = math.floor(evt.addr / 8) + 1
	local offs = (evt.addr % 8)
	local item = ActionHandlers[hash] and ActionHandlers[hash][num] and ActionHandlers[hash][num][resp]
	print("action_handling", num, offs, resp, hash, dump(item), dump(ActionHandlers))
	if item then
		pdp13lib.event_response(vm, resp, item.func(item.pos, offs, evt.data) or 0)
		return item.credit
	end
	return CREDIT
end	

local function update_formspec(pos, mem, vm, last)
	if vm then
		local cpu = pdp13lib.get_cpu_reg(vm)
		if cpu then
			M(pos):set_string("formspec", formspec1(mem, cpu, last))
			return
		end
	end
	M(pos):set_string("formspec", formspec1(mem))
end	

function pdp13.call_cpu(pos, vm, cycles)
	local credit = CREDIT
	local resp
	while credit > 0 do
		resp = pdp13lib.run(vm, cycles)
		if resp > VM13_DELAY then
			credit = credit - action_handling(pos, vm, resp)
		else
			credit = 0
		end
	end
	local mem = tubelib2.get_mem(pos)
	if mem.upd_cnt then
		mem.state = resp
		update_formspec(pos, mem, vm, false)
		mem.upd_cnt = mem.upd_cnt - 1
		if mem.upd_cnt < 0 then
			mem.upd_cnt = nil
		end
	end
end

local function single_step(pos, vm)
	local resp = pdp13lib.run(vm, 1)
	if resp > VM13_DELAY then
		action_handling(pos, vm, resp)
	end
	local mem = tubelib2.get_mem(pos)
	mem.upd_cnt = UPD_COUNT
	mem.state = (resp > VM13_OK and resp) or VM13_STOP
	update_formspec(pos, mem, vm, false)
end

local function on_receive_fields_started(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = tubelib2.get_mem(pos)
	local owner = M(pos):get_string("owner")
	local vm = pdp13.vm_get(owner, pos)
	
	if fields.tab == "2" then
		M(pos):set_string("formspec", formspec2(pos))
	elseif fields.tab == "1" then
		update_formspec(pos, mem, vm, false)
	elseif fields.stop then
		pdp13.vm_suspend(owner, pos)
		mem.state = VM13_STOP
		mem.started = false
		update_formspec(pos, mem, vm, false)
		swap_node(pos, "pdp13:cpu1")
	elseif fields.update then
		mem.upd_cnt = UPD_COUNT
		update_formspec(pos, mem, vm, false)
	end
end

local function on_receive_fields_stopped(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = tubelib2.get_mem(pos)
	local owner = M(pos):get_string("owner")
	local vm = pdp13.vm_get(owner, pos)
	
	if fields.tab == "2" then
		M(pos):set_string("formspec", formspec2(pos))
	elseif fields.tab == "1" then
		update_formspec(pos, mem, vm, false)
	elseif fields.key_enter_field == "address" and fields.key_enter == "true" then
		local idx, num = string.match (fields.address, "^([0-9]+)=([0-9]*)$")
		local owner = M(pos):get_string("owner")
		if idx and num and (num == "" or techage.not_protected(num, owner)) then
			local t = get_tbl(pos, "addr_tbl")
			t[tonumber(idx)] = num
			set_tbl(pos, "addr_tbl", t)
			M(pos):set_string("formspec", formspec2(pos))
		end
	elseif fields.key_enter_field == "command" and fields.key_enter == "true" then
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
		mem.started = true
		mem.state = VM13_OK
		mem.upd_cnt = UPD_COUNT
		update_formspec(pos, mem, vm)
		swap_node(pos, "pdp13:cpu1_on")
	elseif fields.examine then
		pdp13lib.examine(vm)
		update_formspec(pos, mem, vm, true)
	elseif fields.step and mem.state ~= VM13_HALT then
		single_step(pos, vm)
	elseif fields.reset then
		mem.state = VM13_STOP
		pdp13lib.loadaddr(vm, 0) 
		update_formspec(pos, mem, vm, false)
	end
end

local function pdp13_command(pos, cmnd)
	if cmnd == "on" then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		pdp13.vm_create(owner, pos)
		pdp13.add_to_owner_list(owner, pos)
		pdp13.update_action_list(pos)
		mem.started = false
		mem.state = VM13_STOP
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
	on_receive_fields = on_receive_fields_stopped,
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
	on_receive_fields = on_receive_fields_started,
	pdp13_command = pdp13_command,
	paramtype2 = "facedir",
	diggable = false,
	groups = {not_in_creative_inventory=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

