--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 CPU

]]--


-- for lazy programmers
local M = minetest.get_meta

local function programmer_cmnd(pos, cmd, payload)
	local dst_num = M(pos):get_string("programmer_number")
	local own_num = M(pos):get_string("node_number")
	return techage.send_single(own_num, dst_num, cmd, payload)
end

local function leds(address, opcode, operand)
	local lLed = {}
	for i = 16,1,-1 do
		if vm16.testbit(address, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",1.30;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if vm16.testbit(opcode, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",2.26;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if vm16.testbit(operand, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",3.22;0.4,0.4;pdp13_led_form.png]"
		end
	end
	return table.concat(lLed, "")
end

local function vm_state(mem)
	if mem.started            then return "image[2.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.monitor            then return "image[3.7,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.STOP then return "" end
	if mem.state == vm16.IN   then return "image[5.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.OUT  then return "image[5.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.HALT then return "image[6.7,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.SYS  then return "image[8.2,0.4;0.4,0.4;pdp13_led_form.png]" end
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

local function formspec(pos, mem, cpu)
	local sLED
	if cpu then
		if vm16.num_operands(cpu.mem0) == 1 then
			sLED = leds(cpu.PC, cpu.mem0, cpu.mem1)
		else
			sLED = leds(cpu.PC, cpu.mem0, 0)
		end
	else
		sLED = leds(0, 0, 0)
	end
	mem.state = mem.state or vm16.STOP
	local state = vm_state(mem)
	local img = mem.started and "pdp13_cpu_form_run.png" or "pdp13_cpu_form.png"
	local regABXY =  mem.regABXY or "A:0000 B:0000 X:0000 Y:0000"
	local cmnd1 = mem.cmnd1 or ">."
	local cmnd2 = mem.cmnd2 or " ."
	local cmnd3 = mem.cmnd3 or " ."
	local redraw = (M(pos):get_int("redraw") or 0) + 1
	M(pos):set_int("redraw", redraw)
	return "size[10,7.7]"..
		"tabheader[0,0;tab;CPU,help;1;;true]"..
		"background[-0.1,-0.2;10.2,5.6;"..img.."]"..
		sLED..
		state..
		"label[-2,-2;"..redraw.."]"..
		"label[5.1,0.81;address]"..
		"label[5.1,1.77;opcode]"..
		"label[5.1,2.73;operand]"..
		
		"label[2.5,0.4; run]"..
		"label[4.0,0.4; mon]"..
		"label[5.5,0.4; i/o]"..
		"label[7.0,0.4; halt]"..
		"label[8.5,0.4; sys]"..
		
		"button[0,5.4;1.7,1;start;start]"..
		"button[1.7,5.4;1.7,1;stop;stop]"..
		
		"button[0,6.3;1.7,1;reset;reset]"..
		"button[1.7,6.3;1.7,1;step;step]"..
		
		"button[0,7.2;1.7,1;address;address]"..
		"button[1.7,7.2;1.7,1;dump;dump]"..
		
		"background[3.5,5.6;6.4,1.7;pdp13_form_mask.png]"..
		"style_type[label,field;font=mono]"..
		"label[3.5,5.5;"..regABXY.."]"..
		"label[3.5,5.9;"..cmnd1.."]"..
		"label[3.5,6.3;"..cmnd2.."]"..
		"label[3.5,6.7;"..cmnd3.."]"..
		
		"field[3.7,7.6;6.6,0.8;command;;]"..
		"button[8.3,7.2;1.7,1;enter;enter]"..
		"field_close_on_enter[command;false]"
end

local function formspec_help()
	local s = vm16.AsmHelp..","..pdp13.SysDesc
	return "size[10,7.7]"..
		"tabheader[0,0;tab;CPU,help;2;;true]"..
		"style_type[table;font=mono]"..
		"table[0.25,0.25;9.5,7.2;help;"..s..";1]"
end
	
local function update_formspec(pos, mem, cpu)
	cpu = cpu or vm16.get_cpu_reg(pos)
	M(pos):set_string("formspec", formspec(pos, mem, cpu))
end	

local function fs_mem_dump(pos, mem, s)
	mem.addr = mem.addr or 0
	local dump = vm16.read_mem(pos, mem.addr, 16)
	mem.regABXY = string.format("%04X: %04X %04X %04X %04X", mem.addr+0, dump[1], dump[2], dump[3], dump[4])
	mem.cmnd1 = string.format("%04X: %04X %04X %04X %04X", mem.addr+4, dump[5], dump[6], dump[7], dump[8])
	mem.cmnd2 = string.format("%04X: %04X %04X %04X %04X", mem.addr+8, dump[9], dump[10], dump[11], dump[12])
	mem.cmnd3 = string.format("%04X: %04X %04X %04X %04X", mem.addr+12, dump[13], dump[14], dump[15], dump[16])
	update_formspec(pos, mem)
	mem.addr = mem.addr + 16
end

local function fs_mem_data(pos, mem, s)
	local s1, s2 = unpack(string.split(s, " "))
	mem.regABXY = mem.cmnd1
	mem.cmnd1 = mem.cmnd2
	-- only address value?
	if string.len(mem.cmnd3) == 5 then
		mem.cmnd2 = ""
	else
		mem.cmnd2 = mem.cmnd3
	end
		
	if s2 then
		local val1 = vm16.hex2number(s1)
		local val2 = vm16.hex2number(s2)
		mem.cmnd3 = string.format("%04X: %04X %04X", mem.addr, val1, val2)
		vm16.poke(pos, mem.addr, val1)
		vm16.poke(pos, mem.addr+1, val2)
		mem.addr = (mem.addr + 2) % 0x10000
	else
		local val1 = vm16.hex2number(s1)
		mem.cmnd3 = string.format("%04X: %04X", mem.addr, val1)
		vm16.poke(pos, mem.addr, val1)
		mem.addr = (mem.addr + 1) % 0x10000
	end
	vm16.set_pc(pos, mem.addr) 
	update_formspec(pos, mem)
end

local function mem_address(pos, mem, s)
	mem.addr = vm16.hex2number(s)
	mem.regABXY = ""
	mem.cmnd1 = ""
	mem.cmnd2 = ""
	mem.cmnd3 = string.format("%04X:", mem.addr)
	vm16.set_pc(pos, mem.addr) 
	update_formspec(pos, mem)
end

local function fs_single_step(pos, mem, resp)
	local cpu = vm16.get_cpu_reg(pos)
	mem.state = (resp > vm16.OK and resp) or vm16.STOP
	mem.regABXY = string.format("A:%04X B:%04X X:%04X Y:%04X", cpu.A, cpu.B, cpu.X, cpu.Y)
	
	local operand = ""
	if pdp13.num_operands(cpu.mem0) == 1 then
		operand = string.format("%04X", cpu.mem1)
	end
	
	if mem.inp_mode == "step" then
		mem.cmnd1 = mem.cmnd2
		mem.cmnd2 = " "..string.sub(mem.cmnd3, 2)
		mem.cmnd3 = string.format(">%04X: %04X %s", cpu.PC, cpu.mem0, operand)
	else
		mem.cmnd1 = " "
		mem.cmnd2 = " "
		mem.cmnd3 = string.format(">%04X: %04X %s", cpu.PC, cpu.mem0, operand)
		mem.inp_mode = "step"
	end
	update_formspec(pos, mem, cpu)
end

local function fs_cpu_stopped(pos, mem, cpu)
	if pos and mem then
		local cpu = cpu or vm16.get_cpu_reg(pos)
		if cpu then
			mem.regABXY = string.format("A:%04X B:%04X X:%04X Y:%04X", cpu.A, cpu.B, cpu.X, cpu.Y)
			
			local operand = ""
			if pdp13.num_operands(cpu.mem0) == 1 then
				operand = string.format("%04X", cpu.mem1)
			end
			
			mem.started = false
			mem.state = vm16.STOP
			mem.cmnd1 = " "
			mem.cmnd2 = " "
			mem.cmnd3 = string.format(">%04X: %04X %s", cpu.PC, cpu.mem0, operand)
			update_formspec(pos, mem, cpu)
		end
	end
end

local function fs_help(pos, mem, s)
	if pos and mem then
		mem.regABXY = ""
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = s
		update_formspec(pos, mem)
	end
end

local function fs_power_off(pos, mem)
	if pos and mem then
		mem.started = false
		mem.monitor = false
		mem.state = vm16.STOP
		mem.regABXY = "off"
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		update_formspec(pos, mem)
	end
end	

local function fs_power_on(pos, mem)
	if pos and mem then
		mem.started = false
		mem.monitor = false
		mem.state = vm16.STOP
		mem.regABXY = "stopped"
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		update_formspec(pos, mem)
	end
end	

local function fs_cpu_running(pos, mem)
	if pos and mem then
		mem.started = true
		mem.state = vm16.STOP
		mem.regABXY = "running"
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		update_formspec(pos, mem)
	end
end	

local function fs_in_monitor(pos, mem)
	if pos and mem then
		mem.started = false
		mem.state = vm16.STOP
		mem.regABXY = "monitor running"
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		local cpu = {PC = 0xF000, mem0 = 0xAA55, mem1 = 0x0F0F}
		update_formspec(pos, mem, cpu)
	end
end	

-- For Rack communication
local function pdp13_on_receive(pos, src_pos, cmnd, data)
	if cmnd == "power" then
		if data == "on" then
			local mem = techage.get_nvm(pos)
			local ram_size = M(pos):get_int("ram_size")
			if ram_size == 0 then ram_size = 4 end
			if vm16.on_power_on(pos, ram_size/4) then
				fs_power_on(pos, mem)
			end
			local number = M(pos):get_string("node_number")
			pdp13.io_store(pos, number)
			return true
		elseif data == "off" then
			minetest.get_node_timer(pos):stop()
			local mem = techage.get_nvm(pos)
			if vm16.on_power_off(pos) then
				swap_node(pos, "pdp13:cpu1")
				fs_power_off(pos, mem)
			end
			return true
		end
	elseif cmnd == "reg_io" then
		--print("reg_io")
		local mem = techage.get_nvm(pos)
		mem.num_ioracks = (mem.num_ioracks or 0) + 1
		return mem.num_ioracks - 1
	elseif cmnd == "reg_tele" then
		M(pos):set_string("telewriter_number", data)
		return M(pos):get_string("node_number")
	elseif cmnd == "reg_prog" then
		M(pos):set_string("programmer_number", data)
		return M(pos):get_string("node_number")
	elseif cmnd == "cpu_num" then
		--print("CPU cpu_num", M(pos):get_string("node_number"))
		return M(pos):get_string("node_number")
	elseif cmnd == "memory" then
		M(pos):set_int("ram_size", data.ram or 4)
		M(pos):set_int("rom_size", data.rom or 0)
	else
		print(cmnd, dump(data))
	end
end

-- update CPU formspec
local function on_update(pos, resp, cpu)
	--print("on_update")
	local mem = techage.get_nvm(pos)
	-- External controlled?
	if mem.monitor then
		programmer_cmnd(pos, "stopped", resp)
		mem.state = resp
		minetest.get_node_timer(pos):stop()
	else
		mem.state = resp
		minetest.get_node_timer(pos):stop()
		swap_node(pos, "pdp13:cpu1")
		fs_cpu_stopped(pos, mem, cpu)
	end
end

-- store all data when CPU gets unloaded
local function on_unload(pos)
	--pdp13.io_store(pos) geht so nicht
end

function pdp13.start_cpu(pos)
	local number = M(pos):get_string("node_number")
	pdp13.reset_output_buffer(number)
	minetest.get_node_timer(pos):start(0.1)
	swap_node(pos, "pdp13:cpu1_on")
end

function pdp13.stop_cpu(pos)
	minetest.get_node_timer(pos):stop()
	swap_node(pos, "pdp13:cpu1")
end

function pdp13.single_step_cpu(pos)
	local number = M(pos):get_string("node_number")
	pdp13.reset_output_buffer(number)
	return vm16.run(pos, 1)
end

function pdp13.exit_monitor(pos)
	local mem = techage.get_nvm(pos)
	pdp13.stop_cpu(pos)
	vm16.set_pc(pos, 0) 
	mem.monitor = false
	mem.addr = 0
	fs_cpu_stopped(pos, mem)
end

vm16.register_callbacks(nil, nil, nil, on_update, on_unload)

local function on_receive_fields_stopped(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = techage.get_nvm(pos)
	local meta = minetest.get_meta(pos)
	--print(vm16.is_loaded(pos), mem.inp_mode, dump(fields))
	
	if mem.monitor then
		if fields.stop then
			pdp13.stop_cpu(pos)
			local mem = techage.get_nvm(pos)
			mem.monitor = false
			programmer_cmnd(pos, "monitor", false)
			fs_cpu_stopped(pos, mem)
		end
		return 
	end
	
	if fields.tab == "2" then
		meta:set_string("storeformspec", meta:get_string("formspec"))
		meta:set_string("formspec", formspec_help())
		return
	elseif fields.tab == "1" then
		meta:set_string("formspec", meta:get_string("storeformspec"))
		return
	end
	
	if vm16.is_loaded(pos) then
		-- change input field mode
		if fields.address then
			mem.inp_mode = "address"
			fs_help(pos, mem, "Enter address:")
		elseif fields.dump then
			mem.inp_mode = "dump"
			fs_mem_dump(pos, mem, fields.command)
		elseif fields.start then
			pdp13.start_cpu(pos)
			fs_cpu_running(pos, mem)
		elseif fields.reset then
			vm16.set_pc(pos, 0) 
			mem.addr = 0
			fs_cpu_stopped(pos, mem)
		elseif fields.step then
			local resp = pdp13.single_step_cpu(pos)
			fs_single_step(pos, mem, resp)
		elseif fields.key_enter_field or fields.enter then
			if fields.command == "mon" then
				if M(pos):get_int("rom_size") > 0 then
					mem.monitor = true
					programmer_cmnd(pos, "monitor", true)
					fs_in_monitor(pos, mem)
				else
					fs_cpu_stopped(pos, mem)
				end
			elseif mem.inp_mode == "address" then
				mem_address(pos, mem, fields.command)
			else
				fs_mem_data(pos, mem, fields.command)
			end
			mem.inp_mode = "data"
		end
	end
end

minetest.register_node("pdp13:cpu1", {
	description = "PDP-13 CPU",
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.4, 0.5, 0.5, 0.4},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
		"pdp13_cpu.png^pdp13_frame.png^pdp13_frame_top.png",
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local mem = techage.get_nvm(pos)
		local meta = M(pos)
		meta:set_string("owner", placer:get_player_name())
		local own_num = techage.add_node(pos, "pdp13:cpu1")
		meta:set_string("node_number", own_num)
		meta:set_string("infotext", "PDP-13 CPU "..own_num)
		update_formspec(pos, mem)
	end,
	on_receive_fields = on_receive_fields_stopped,
	pdp13_on_receive = pdp13_on_receive,
	
	can_dig = function(pos)
		return vm16.is_loaded(pos) == false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata)
		techage.remove_node(pos, oldnode, oldmetadata)
		techage.del_mem(pos)
	end,
	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

local function on_receive_fields_started(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	if fields.stop then
		pdp13.stop_cpu(pos)
		local mem = techage.get_nvm(pos)
		mem.monitor = false
		programmer_cmnd(pos, "monitor", false)
		fs_cpu_stopped(pos, mem)
	end
end

minetest.register_node("pdp13:cpu1_on", {
	description = "PDP-13 CPU",
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.4, 0.5, 0.5, 0.4},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_side.png",
		"pdp13_back.png",
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
	on_timer = function(pos, elapsed)
		return vm16.run(pos) < vm16.HALT
	end,
--	on_timer = function(pos, elapsed)
--		local t = minetest.get_us_time()
--		local res = vm16.run(pos)
--		t = minetest.get_us_time() - t
--		print("on_timer", t)
--		return res < vm16.HALT
--	end,
	on_receive_fields = on_receive_fields_started,
	pdp13_on_receive = pdp13_on_receive,
	paramtype2 = "facedir",
	diggable = false,
	groups = {not_in_creative_inventory=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

techage.register_node({"pdp13:cpu1", "pdp13:cpu1_on"}, {
	on_recv_message = function(pos, src, topic, payload)
		--print("CPU on_recv_message", src, topic, payload)
		if topic == "on" then
			local number = M(pos):get_string("node_number")
			pdp13.on_cmnd_input(number, src, 1)
		elseif topic == "off" then
			local number = M(pos):get_string("node_number")
			pdp13.on_cmnd_input(number, src, 0)
		elseif topic == "write_h16" then
			local node = minetest.get_node(pos)
			if node.name == "pdp13:cpu1" then
				return vm16.write_h16(pos, payload)
			end
		elseif topic == "read_h16" then
			local node = minetest.get_node(pos)
			if node.name == "pdp13:cpu1" then
				return vm16.read_h16(pos)
			end
		else
			return "unsupported"
		end
	end,
})	

minetest.register_lbm({
    label = "PDP13 Load CPU",
    name = "pdp13:load_cpu",
    nodenames = {"pdp13:cpu1", "pdp13:cpu1_on"},
    run_at_every_load = true,
    action = function(pos, node)
		local mem = techage.get_nvm(pos)
		local number = M(pos):get_string("node_number")
		pdp13.io_restore(pos, number)
		if vm16.on_load(pos) then
			if node.name == "pdp13:cpu1" then
				fs_power_on(pos, mem)
			else
				fs_cpu_running(pos, mem)
			end
		else
			fs_power_off(pos, mem)
		end
	end
})

minetest.register_craft({
	output = "pdp13:cpu1",
	recipe = {
		{"pdp13:chassis", "dye:magenta", ""},
		{"pdp13:ram4k", "pdp13:ic2", ""},
		{"pdp13:ic1", "pdp13:ic1", ""},
	},
})
