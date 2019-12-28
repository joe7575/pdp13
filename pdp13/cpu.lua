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

local vm_input  = pdp13.vm_input
local vm_output = pdp13.vm_output
local vm_system = pdp13.vm_system


local function leds(address, data1, data2)
	local lLed = {}
	for i = 16,1,-1 do
		if vm16.testbit(address, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",1.3;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if vm16.testbit(data1, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",2.4;0.4,0.4;pdp13_led_form.png]"
		end
	end
	for i = 16,1,-1 do
		if vm16.testbit(data2, 16-i) then
			local xpos = -0.18 + i * 0.399
			lLed[#lLed+1] = "image["..xpos..",3.15;0.4,0.4;pdp13_led_form.png]"
		end
	end
	return table.concat(lLed, "")
end

local function vm_state(mem)
	if mem.started            then return "image[2.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.STOP then return "" end
	if mem.state == vm16.IN   then return "image[4.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.OUT  then return "image[4.2,0.4;0.4,0.4;pdp13_led_form.png]" end
	if mem.state == vm16.HALT then return "image[6.2,0.4;0.4,0.4;pdp13_led_form.png]" end
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

local function hex8(u8)
	return string.format("%02X", u8)
end
local function hex16(u16)
	return string.format("%04X", u16)
end

local function formspec1(mem, cpu)
	local sLED
	if cpu then
		sLED = leds(cpu.PC, cpu.mem0, cpu.mem1)
	else
		sLED = leds(0, 0, 0)
	end
	mem.state = mem.state or vm16.STOP
	local state = vm_state(mem)
	local img = mem.started and "pdp13_cpu_form_run.png" or "pdp13_cpu_form.png"
	local cmnd1 = mem.cmnd1 or ""
	local cmnd2 = mem.cmnd2 or ""
	local cmnd3 = mem.cmnd3 or ""
	return "size[10,7.7]"..
		"tabheader[0,0;tab;CPU,I/O;1;;true]"..
		"background[-0.1,-0.2;10.2,5.6;"..img.."]"..
		sLED..
		state..
		"label[5.1,0.82;address]"..
		"label[5.1,1.93;data]"..
		
		"label[2.5,0.4; run]"..
		"label[4.5,0.4; i/o]"..
		"label[6.5,0.4; halt]"..
		"label[8.5,0.4; sys]"..
		
		"button[0,5.4;1.8,1;start;start]"..
		"button[1.9,5.4;1.8,1;stop;stop]"..
		
		"button[0,6.3;1.8,1;step;step]"..
		"button[1.9,6.3;1.8,1;reset;reset]"..
		
		"button[0,7.2;1.8,1;examine;examine]"..
		"button[1.9,7.2;1.8,1;register;register]"..
		
		"background[3.8,5.6;6.1,1.2;pdp13_form_mask.png]"..
		"label[3.8,5.5;"..cmnd1.."]"..
		"label[3.8,5.9;"..cmnd2.."]"..
		"label[3.8,6.3;"..cmnd3.."]"..
		
		"label[3.8,6.8;l <addr> (load)     d <val> (deposite)]"..
		
		"field[4,7.6;6.3,0.8;command;;]"..
		"field_close_on_enter[command;false]"
end

local function info_cmnd(num)
	if num ~= "" then
		local pos = techage.get_node_info(num).pos
		if pos then
			local info = techage.send_single(0, num, "pdp13_info")
			if info then
				local node = techage.get_node_lvm(pos)
				local ndef = minetest.registered_nodes[node.name]
				if ndef and ndef.description then
					local help = ndef.description..":\n"..(info.help or "?")
					return info.type or "", minetest.formspec_escape(help)
				end
			end
		end
	end
	return "", ""
end
	
local function to_hexnumbers(s)
	local codes = {}
	for _,s in ipairs(string.split(s, " ")) do
		s = s or ""
		s = string.match(s:trim(), "^([0-9a-fA-F]+)$") or ""
		local val = tonumber(s, 16)
		if val then
			codes[#codes+1] = val
		end
	end
	return codes
end

local function formspec2(pos)
	local tbl = get_tbl(pos, "addr_tbl")
	local t = {"label[0.0,0;No]label[0.8,0;I/O Addr]label[2.2,0;Number]label[3.5,0;Info]",
	           "label[5.2,0;No]label[6.0,0;I/O Addr]label[7.4,0;Number]label[8.7,0;Info]"}
	for i = 1,16 do
		local ypos = 0.1 + i * 0.4
		local addr = hex8((i-1) * 8).." - "..hex8((i-1) * 8 + 7)
		local num = tbl[i] or ""
		local info, tooltip = info_cmnd(num)
		
		-- label
		t[#t+1] = "label[0.0,"..ypos..";"..(i-1).."]"
		-- I/O Addr
		t[#t+1] = "label[0.8,"..ypos..";"..addr.."]"
		-- node number
		t[#t+1] = "label[2.2,"..ypos..";"..num.."]"
		-- Info
		t[#t+1] = "label[3.5,"..ypos..";"..info.."]"		
		-- tooltip
		t[#t+1] = "tooltip[3.5,"..ypos..";2,0.5;"..tooltip.."]"
	end	
	for i = 17,32 do
		local ypos = 0.1 + (i-16) * 0.4
		local addr = hex8((i-1) * 8).." - "..hex8((i-1) * 8 + 7)
		local num = tbl[i] or ""
		local info, tooltip = info_cmnd(num)
		
		-- label
		t[#t+1] = "label[5.2,"..ypos..";"..(i-1).."]"		
		-- I/O Addr
		t[#t+1] = "label[6.0,"..ypos..";"..addr.."]"
		-- node number
		t[#t+1] = "label[7.4,"..ypos..";"..num.."]"
		-- Info
		t[#t+1] = "label[8.7,"..ypos..";"..info.."]"		
		-- tooltip
		t[#t+1] = "tooltip[8.7,"..ypos..";2,0.5;"..tooltip.."]"
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

local function update_formspec(pos, mem, vm, cpu)
	if vm then
		cpu = cpu or vm16.get_cpu_reg(vm)
		if cpu then
			M(pos):set_string("formspec", formspec1(mem, cpu))
			return
		end
	end
	M(pos):set_string("formspec", formspec1(mem))
end	

local function load_extensions(pos)
	local pos2 = minetest.find_node_near(pos, 1, {"pdp13:chassis", "pdp13:chassis_top"})
	if pos2 then
		local ndef = minetest.registered_nodes[minetest.get_node(pos2).name]
		if ndef and ndef.pdp13_get_extensions then
			local tbl = ndef.pdp13_get_extensions(pos2)
			for _,item in ipairs(tbl) do
				print(hex16(item.addr), item.type)
			end
			return tbl
		end
	end
	return {}
end

local function chassis_set_running(pos, running)
	local pos2 = minetest.find_node_near(pos, 1, {"pdp13:chassis", "pdp13:chassis_top"})
	if pos2 then
		local ndef = minetest.registered_nodes[minetest.get_node(pos2).name]
		if ndef and ndef.pdp13_set_running then
			ndef.pdp13_set_running(pos2, running)
		end
	end
end
	
local function disassemble(vm, mem)
	mem.cmnd1 = mem.cmnd2
	mem.cmnd2 = mem.cmnd3
	local reg = vm16.get_cpu_reg(vm)
	local _,s = pdp13.unasm_command(vm, "u "..hex16(reg.PC))
	s = string.gsub(s, " ", "\xE2\x80\x87")
	mem.cmnd3 = minetest.formspec_escape(s)
end

local function mem_dump(vm, mem, cpu)
	mem.cmnd1 = mem.cmnd2
	mem.cmnd2 = mem.cmnd3
	local _,s = pdp13.dump_command(vm, "d "..hex16(cpu.PC))
	s = string.gsub(s, " ", "\xE2\x80\x87")
	mem.cmnd3 = minetest.formspec_escape(s)
end

local function CPU_register(vm, mem)
	local reg = vm16.get_cpu_reg(vm)
	mem.cmnd1 = mem.cmnd2
	mem.cmnd2 = string.format("A:%04X  B:%04X    C:%04X     D:%04X", reg.A, reg.B, reg.C, reg.D)
	mem.cmnd3 = string.format("X:%04X  Y:%04X  SP:%04X  PC:%04X", reg.X, reg.Y, reg.SP, reg.PC)
end

function pdp13.call_cpu(pos, vm, cycles)
	local resp = vm16.call(vm, pos, cycles, vm_input, vm_output, vm_system)
	if resp >= vm16.HALT then
		swap_node(pos, "pdp13:cpu1")
		local mem = tubelib2.get_mem(pos)
		mem.started = false		
		mem.state = resp
		update_formspec(pos, mem, vm)
	end
	return resp < vm16.HALT
end

-- In case of an error
function pdp13.turn_cpu_off(pos)
	if pos then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		mem.started = false
		mem.power = false
		mem.state = vm16.STOP
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		if owner ~= "" then
			pdp13.remove_from_owner_list(owner, pos)
			pdp13.vm_destroy(owner, pos)
		end
		swap_node(pos, "pdp13:cpu1")
		update_formspec(pos, mem)
		chassis_set_running(pos, false)
	end
end	

local function single_step(pos, vm)
	local resp = vm16.call(vm, pos, 1, vm_input, vm_output, vm_system)
	local mem = tubelib2.get_mem(pos)
	mem.state = (resp > vm16.OK and resp) or vm16.STOP
	disassemble(vm, mem)
	update_formspec(pos, mem, vm)
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
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		update_formspec(pos, mem, vm)
	elseif fields.stop then
		pdp13.vm_suspend(owner, pos)
		mem.state = vm16.STOP
		mem.started = false
		update_formspec(pos, mem, vm)
		swap_node(pos, "pdp13:cpu1")
	end
end

local function on_receive_fields_stopped(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	
	local mem = tubelib2.get_mem(pos)
	print(dump(mem))
	local owner = M(pos):get_string("owner")
	
	-- I/O menu
	if fields.tab == "2" then
		M(pos):set_string("formspec", formspec2(pos))
		return
	elseif not mem.power and fields.key_enter_field == "address" and fields.key_enter == "true" then
		local idx, num = string.match (fields.address, "^([0-9]+) *= *([0-9]*)$")
		if idx and num and (num == "" or techage.not_protected(num, owner)) then
			local t = get_tbl(pos, "addr_tbl")
			idx = tonumber(idx) + 1
			if idx <= 32 then
				t[tonumber(idx)] = num
				set_tbl(pos, "addr_tbl", t)
				M(pos):set_string("formspec", formspec2(pos))
				pdp13.update_action_list(pos)
			end
		end
		return
	end
	
	-- passive CPU menu
	if not mem.power then
		if fields.tab == "1" then
			mem.cmnd1 = ""
			mem.cmnd2 = ""
			mem.cmnd3 = ""
			update_formspec(pos, mem)
		end
		return
	end
	
	local vm = pdp13.vm_get(owner, pos)
	if not vm then return end
	
	-- active CPU menu
	if fields.tab == "1" then
		mem.cmnd1 = ""
		mem.cmnd2 = ""
		mem.cmnd3 = ""
		update_formspec(pos, mem, vm)
	elseif fields.key_enter_field == "command" and fields.key_enter == "true" then
		local cmnd, val = string.match (fields.command, "^([wrld]) +([0-9a-fA-F]+)$")
		if cmnd and val then
			mem.cmnd1 = mem.cmnd2
			mem.cmnd2 = mem.cmnd3
			mem.cmnd3 = fields.command
		elseif string.sub(fields.command, 1, 1) == "w" then
			local data = to_hexnumbers(string.sub(fields.command, 2))
			local reg = vm16.get_cpu_reg(vm)
			if data and reg then
				print("write", reg.PC, #data)
				vm16.write_mem(vm, reg.PC, data)
			end			
		end
		if cmnd == "l" then 
			mem.state = vm16.STOP
			vm16.loadaddr(vm, tonumber(val, 16))
			disassemble(vm, mem)
			update_formspec(pos, mem, vm)
		elseif cmnd == "d" then
			local cpu = vm16.get_cpu_reg(vm)
			mem.state = vm16.STOP
			vm16.deposit(vm, tonumber(val, 16)) 
			update_formspec(pos, mem, vm, cpu)
		elseif cmnd == "r" then 
			print(dump(vm16.get_cpu_reg(vm)))
		end 
	elseif fields.start and mem.state ~= vm16.HALT then
		pdp13.vm_store(owner, pos)
		pdp13.vm_resume(owner, pos)
		mem.started = true
		mem.state = vm16.OK
		mem.upd_cnt = UPD_COUNT
		M(pos):set_string("formspec", formspec1(mem))
		swap_node(pos, "pdp13:cpu1_on")
	elseif fields.examine then
		local cpu = vm16.get_cpu_reg(vm)
		mem_dump(vm, mem, cpu)
		update_formspec(pos, mem, vm, cpu)
		vm16.loadaddr(vm, cpu.PC + 4)
	elseif fields.step then
		single_step(pos, vm)
	elseif fields.reset then
		mem.state = vm16.STOP
		vm16.loadaddr(vm, 0) 
		update_formspec(pos, mem, vm)
	elseif fields.register then
		CPU_register(vm, mem)
		update_formspec(pos, mem, vm)
	end
end

local function pdp13_command(pos, cmnd)
	if cmnd == "on" then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		chassis_set_running(pos, true)
		pdp13.vm_create(owner, pos, load_extensions(pos))
		pdp13.add_to_owner_list(owner, pos)
		pdp13.update_action_list(pos)
		mem.started = false
		mem.power = true
		mem.state = vm16.STOP
	elseif cmnd == "off" then
		local mem = tubelib2.get_mem(pos)
		local owner = M(pos):get_string("owner")
		if mem.started then
			pdp13.vm_suspend(owner, pos)
		end
		mem.started = false
		mem.power = false
		mem.state = vm16.STOP
		chassis_set_running(pos, false)
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
		local own_num = techage.add_node(pos, "pdp13:cpu1")
		M(pos):set_string("node_number", own_num)
		update_formspec(pos, mem)
	end,
	on_receive_fields = on_receive_fields_stopped,
	pdp13_command = pdp13_command,
	after_dig_node = function(pos, oldnode)
		local owner = M(pos):get_string("owner")
		pdp13.vm_destroy(owner, pos)
		--techage.power.after_dig_node(pos, oldnode)
		tubelib2.del_mem(pos)
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

