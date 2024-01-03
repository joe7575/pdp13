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
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos

local CYCLE_TIME = 0.1

local function programmer_cmnd(pos, cmd, payload)
	local dst_num = M(pos):get_string("programmer_number")
	local own_num = M(pos):get_string("node_number")
	return pdp13.send_single(own_num, dst_num, cmd, payload)
end

function pdp13.operator_cmnd(pos, cmd, payload)
	local dst_num = M(pos):get_string("telewriter_number")
	local own_num = M(pos):get_string("node_number")
	return pdp13.send_single(own_num, dst_num, cmd, payload)
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
	if mem.state == vm16.ERROR then return "" end
	if mem.started            then return "image[2.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.monitor            then return "image[3.7,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.STOP then return "" end
	if mem.state == vm16.IN   then return "image[5.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.OUT  then return "image[5.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.BREAK then return "image[6.7,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.SYS  then return "image[8.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.ERROR then return "image[8.2,0.4;0.4,0.4;pdp13_led_form.png]" end
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
		"label[7.0,0.4; brk]"..
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
	local s = pdp13.AsmHelp..","..pdp13.SysDesc
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
	mem.addr = mem.addr or 0
	mem.regABXY = mem.cmnd1 or ""
	mem.cmnd1 = mem.cmnd2 or ""
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
	update_formspec(pos, mem, cpu, resp)
end

local function fs_cpu_stopped(pos, mem, cpu, resp)
	if pos and mem then
		local cpu = cpu or vm16.get_cpu_reg(pos)
		if cpu then
			mem.regABXY = string.format("A:%04X B:%04X X:%04X Y:%04X", cpu.A, cpu.B, cpu.X, cpu.Y)
			
			local operand = ""
			if pdp13.num_operands(cpu.mem0) == 1 then
				operand = string.format("%04X", cpu.mem1)
			end
			
			mem.started = false
			mem.state = resp or vm16.STOP
			mem.cmnd1 = " "
			mem.cmnd2 = " "
			if resp == vm16.ERROR then
				mem.cmnd3 = string.format(">%04X: %s", cpu.PC-1, "illegal opcode!")
				minetest.sound_play("pdp13_beep", {
					pos = pos, 
					gain = 1,
					max_hear_distance = 5})
			else
				mem.cmnd3 = string.format(">%04X: %04X %s", cpu.PC, cpu.mem0, operand)
			end
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

local function reset_periphery_settings(meta)
	meta:set_string("telewriter_number", "")
	meta:set_string("terminal_pos", "")
	meta:set_string("programmer_number", "")
	meta:set_string("tape_pos", "")
	meta:set_string("hdd_pos", "")
	meta:set_string("uid_t", "")
	meta:set_string("uid_h", "")
	meta:set_int("has_tape", 0)
	meta:set_int("has_hdd", 0)
	meta:set_int("ram_size", 0)
	meta:set_int("rom_size", 0)
end

local function add_periphery_settings(pos, meta, cmnd, data)
	--print("add_periphery_settings", cmnd, dump(data))
	if cmnd == "reg_tele" then
		meta:set_string("telewriter_number", data)
		return M(pos):get_string("node_number")
	elseif cmnd == "reg_term" then
		meta:set_string("terminal_pos", P2S(data))
		return pos
	elseif cmnd == "reg_prog" then
		meta:set_string("programmer_number", data)
		return meta:get_string("node_number")
	elseif cmnd == "reg_tape" then
		meta:set_string("tape_pos", P2S(data))
		meta:set_int("has_tape", 1)
		return pos
	elseif cmnd == "reg_hdd" then
		meta:set_string("hdd_pos", P2S(data))
		meta:set_int("has_hdd", 1)
		return pos
	elseif cmnd == "memory" then
		meta:set_int("ram_size", data.ram or 4)
		meta:set_int("rom_size", data.rom or 0)
		return pos
	else
		return false
	end
end

-- For curious admins
local function log_expansion_stage(pos)
	local meta = M(pos)
	spos = P2S(pos)
	local owner = meta:get_string("owner")
	local rom_size = meta:get_int("rom_size")
	local ram_size = meta:get_int("ram_size")
	local tape_drive = meta:get_int("has_tape") == 1 and 1 or 0
	local hard_disk  = meta:get_int("has_hdd") == 1 and 1 or 0

	local total_num1 = 0 
	local total_num2 = 0
	local total_size1 = 0
	local total_size2 = 0

	if tape_drive == 1 then
		total_num1, total_size1 = pdp13.total_num_and_size(pos, "t")
	end
	if hard_disk == 1 then
		total_num2, total_size2 = pdp13.total_num_and_size(pos, "h")
	end
		
	local s1 = "Owner: " .. owner .. ", Pos: " .. spos .. ", ROM size: " .. rom_size .. ", RAM size: " .. ram_size
	local s2 = "Tape drive (files/size): " .. total_num1 .. "/" .. pdp13.kbyte(total_size1)
	local s3 = "Hard disk (files/size): " .. total_num2 .. "/" .. pdp13.kbyte(total_size2)
	minetest.log("action", "PDP-13: " .. s1 .. ", " .. s2 .. ", " .. s3)
end

local function selftest(pos, mem, number)
	if pos and mem then
		local rom_size = pdp13.tROM_SIZE[M(pos):get_int("rom_size")]
		local ram_size = M(pos):get_int("ram_size")
		local io_size = (mem.num_ioracks or 0) * 8
		local telewriter = M(pos):get_string("telewriter_number") ~= "" and "Telewriter..ok  " or ""
		local terminal   = M(pos):get_string("terminal_pos") ~= "" and "Terminal..ok" or ""
		local programmer = M(pos):get_string("programmer_number") ~= "" and "Programmer..ok" or ""
		local tape_drive = M(pos):get_int("has_tape") == 1 and "Tape drive..ok  " or ""
		local hard_disk  = M(pos):get_int("has_hdd") == 1 and "Hard disk..ok" or ""
			
		mem.regABXY = "RAM="..ram_size.."K   ROM="..rom_size.."K   I/O="..io_size
		mem.cmnd1   = telewriter..terminal
		mem.cmnd2   = programmer
		if rom_size >= 16 then
			mem.cmnd3 = tape_drive..hard_disk
		else
			mem.cmnd3 = ""
		end
		update_formspec(pos, mem)
	end
end

-- For Rack communication
local function pdp13_on_receive(pos, src_pos, cmnd, data)
	--print("pdp13_on_receive", cmnd, data)
	if cmnd == "power" then
		if data == "on" then
			local mem = pdp13.get_nvm(pos)
			local meta = M(pos)
			local ram_size = meta:get_int("ram_size") + 4
			local rom_size = meta:get_int("rom_size")
			if vm16.on_power_on(pos, ram_size/4) then
				fs_power_on(pos, mem)
			end
			mem.breakpoints = {}
			local number = meta:get_string("node_number")
			pdp13.io_store(pos, number)
			selftest(pos, mem, number)
			local has_hdd = meta:get_int("has_hdd") == 1 and rom_size >= 2
			pdp13.init_filesystem(pos, false, has_hdd)
			return true
		elseif data == "off" then
			minetest.get_node_timer(pos):stop()
			reset_periphery_settings(M(pos))
			if vm16.on_power_off(pos) then
				swap_node(pos, "pdp13:cpu1")
				local mem = pdp13.get_nvm(pos)
				fs_power_off(pos, mem)
			end
			return true
		end
	elseif cmnd == "reg_io" then
		--print("reg_io")
		local mem = pdp13.get_nvm(pos)
		mem.num_ioracks = (mem.num_ioracks or 0) + 1
		return mem.num_ioracks - 1
	elseif cmnd == "cpu_num" then
		return M(pos):get_string("node_number")
	elseif cmnd == "mount_t" then
		if data and data ~= "" then
			local uid
			if data ~= true then
				uid = pdp13.set_uid(pos, "t", data)
			else
				uid = pdp13.get_uid(pos, "t")
			end	
			pdp13.mount_drive(pos, "t", true)
			pdp13.init_filesystem(pos, true)
			return uid
		else
			pdp13.del_uid(pos, "t")
			pdp13.mount_drive(pos, "t", false)
		end
	else
		return add_periphery_settings(pos, M(pos), cmnd, data)
	end
end

-- update CPU formspec
local function on_update(pos, resp, cpu)
	local mem = pdp13.get_nvm(pos)
	--print("on_update", mem.monitor, resp)
	-- External controlled?
	if mem.monitor then
		programmer_cmnd(pos, "stopped", resp)
		mem.state = resp
		minetest.get_node_timer(pos):stop()
	else
		mem.state = resp
		minetest.get_node_timer(pos):stop()
		swap_node(pos, "pdp13:cpu1")
		fs_cpu_stopped(pos, mem, cpu, resp)
	end
end

local cpu_def = {
	cycle_time = 0.1, -- timer cycle time
	instr_per_cycle = 10000,
	input_costs = 1000,  -- number of instructions
	output_costs = 5000, -- number of instructions
	system_costs = 2000, -- number of instructions
	on_input = pdp13.on_input,
	on_output = pdp13.on_output,
	on_system = pdp13.on_system,
	on_update = on_update,
}

function pdp13.start_cpu(pos)
	local number = M(pos):get_string("node_number")
	pdp13.reset_output_buffer(number)
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	swap_node(pos, "pdp13:cpu1_on")
end

function pdp13.stop_cpu(pos)
	minetest.get_node_timer(pos):stop()
	swap_node(pos, "pdp13:cpu1")
end

function pdp13.single_step_cpu(pos)
	local mem = pdp13.get_nvm(pos)
	local number = M(pos):get_string("node_number")
	pdp13.reset_output_buffer(number)
	return vm16.run(pos, cpu_def, mem.breakpoints, 1)
end

function pdp13.exit_monitor(pos)
	local mem = pdp13.get_nvm(pos)
	pdp13.stop_cpu(pos)
	vm16.set_pc(pos, 0) 
	mem.monitor = false
	mem.addr = 0
	fs_cpu_stopped(pos, mem)
end

function pdp13.cpu_freeze(pos, freeze)
	if freeze then
		minetest.get_node_timer(pos):stop()
	else
		minetest.get_node_timer(pos):start(CYCLE_TIME)
	end
end

local function on_receive_fields_stopped(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = pdp13.get_nvm(pos)
	local meta = minetest.get_meta(pos)
	--print(vm16.is_loaded(pos), mem.inp_mode, dump(fields))
	
	if mem.monitor then
		if fields.stop then
			pdp13.stop_cpu(pos)
			local mem = pdp13.get_nvm(pos)
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
			local rom_size = pdp13.tROM_SIZE[M(pos):get_int("rom_size")]
			if fields.command == "mon" then
				if rom_size >= 8 then
					mem.monitor = true
					programmer_cmnd(pos, "monitor", true)
					fs_in_monitor(pos, mem)
				else
					fs_cpu_stopped(pos, mem)
				end
			elseif fields.command == "boot" then
				if rom_size < 16 then
					fs_help(pos, mem, "error 1")
				else
					local sts = pdp13.cold_start(pos)
					if sts == 1 then
						fs_cpu_running(pos, mem)
						pdp13.start_cpu(pos)
					else
						fs_help(pos, mem, "error "..sts)
					end
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
		local mem = pdp13.get_nvm(pos)
		local meta = M(pos)
		meta:set_string("owner", placer:get_player_name())
		local own_num = pdp13.add_node(pos, "pdp13:cpu1")
		meta:set_string("node_number", own_num)  -- for techage
		meta:set_string("own_number", own_num)  -- for tubelib
		meta:set_string("infotext", "PDP-13 CPU "..own_num)
		update_formspec(pos, mem)
	end,
	on_receive_fields = on_receive_fields_stopped,
	pdp13_on_receive = pdp13_on_receive,
	
	can_dig = function(pos)
		return vm16.is_loaded(pos) == false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata)
		pdp13.remove_node(pos, oldnode, oldmetadata)
		pdp13.del_mem(pos)
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
		local mem = pdp13.get_nvm(pos)
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
		local mem = pdp13.get_nvm(pos)
		return vm16.run(pos, cpu_def, mem.breakpoints) < vm16.HALT
	end,
	on_receive_fields = on_receive_fields_started,
	pdp13_on_receive = pdp13_on_receive,
	paramtype2 = "facedir",
	diggable = false,
	groups = {not_in_creative_inventory=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

pdp13.register_node({"pdp13:cpu1", "pdp13:cpu1_on"}, {
	on_recv_message = function(pos, src, topic, payload)
		if pdp13.tubelib then
			pos, src, topic, payload = pos, "000", src, topic
		end
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
		local mem = pdp13.get_nvm(pos)
		local number = M(pos):get_string("node_number")
		pdp13.io_restore(pos, number)
		if vm16.on_load(pos) then
			if node.name == "pdp13:cpu1" then
				if mem.monitor then
					fs_in_monitor(pos, mem)
				else
					fs_power_on(pos, mem)
				end
			else
				fs_cpu_running(pos, mem)
			end
		else
			fs_power_off(pos, mem)
		end
		--minetest.after(2, log_expansion_stage, pos)
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
