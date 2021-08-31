 --[[

	PDP-13
	======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Wrapper for alternative support of Techage and TechPack

]]--

pdp13.tubelib = minetest.global_exists("tubelib")

local MemStore = {}

local function stub() end

if minetest.global_exists("techage") then
	
	pdp13.get_nvm =  techage.get_nvm
	pdp13.get_mem = techage.get_mem
	pdp13.del_mem = techage.del_mem
	pdp13.add_manual_items = techage.add_manual_items
	pdp13.add_to_manual = techage.add_to_manual
	pdp13.send_single = techage.send_single
	pdp13.get_node_info = techage.get_node_info
	pdp13.add_node = techage.add_node
	pdp13.remove_node = techage.remove_node
	pdp13.register_node = techage.register_node

elseif minetest.global_exists("tubelib") then
	
	pdp13.get_nvm =  tubelib2.get_mem
	pdp13.get_mem = function(pos)
		local hash = minetest.hash_node_position(pos)
		if not MemStore[hash] then
			MemStore[hash] = {}
		end
		return MemStore[hash]
	end
	pdp13.del_mem = tubelib2.del_mem
	pdp13.add_manual_items = stub
	pdp13.add_to_manual = stub
	pdp13.send_single = function(src, number, topic, payload)
		if type(number) == "number" then
			number = string.format("%.04u", number)
		end
		print("send_request", number, topic, payload)
		return tubelib.send_request(number, topic, payload)
	end
	pdp13.get_node_info = function(number)
		number = string.format("%.04u", tonumber(number) or 0)
		return tubelib.get_node_info(number)
	end
	pdp13.add_node = tubelib.add_node
	pdp13.remove_node = tubelib.remove_node
	pdp13.register_node = function(names, node_definition)
		local add_names = {unpack(names, 2)}
		tubelib.register_node(names[1], add_names, node_definition)
	end

end

