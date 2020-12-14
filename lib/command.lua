--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Helper Functions

]]--


pdp13.AllNodes = {
	"pdp13:cpu1", "pdp13:cpu1_on",
	"pdp13:power1", "pdp13:power1_on",
	"pdp13:io_rack", "pdp13:io_rack_top",
	"pdp13:mem_rack",
}

-- For communication purposes between PDP13 nodes.
-- All nodes have to be in an area of 5x5x5 nodes.
-- src_pos: sender pos
-- names:   destination node names
-- cmnd:    command string
-- data:    any command related data
-- range:   search range (optional)

-- Send to one/first node and return result
function pdp13.send(src_pos, names, cmnd, data, range)
	range = range or 2
	local dest_pos = minetest.find_node_near(src_pos, range, names)
	if dest_pos then
		local ndef = minetest.registered_nodes[minetest.get_node(dest_pos).name]
		if ndef and ndef.pdp13_on_receive then
			return ndef.pdp13_on_receive(dest_pos, src_pos, cmnd, data)
		end
	end
end

-- Provide for all nodes, returns the number of receivers
function pdp13.publish(src_pos, names, cmnd, data, range)
	local cnt = 0
	range = range or 2
	local pos1 = {x = src_pos.x-range, y = src_pos.y-range, z = src_pos.z-range}
	local pos2 = {x = src_pos.x+range, y = src_pos.y+range, z = src_pos.z+range}
	for _, dest_pos in ipairs(minetest.find_nodes_in_area(pos1, pos2, names)) do
		local ndef = minetest.registered_nodes[minetest.get_node(dest_pos).name]
		if ndef and ndef.pdp13_on_receive then
			cnt = cnt + (ndef.pdp13_on_receive(dest_pos, src_pos, cmnd, data) and 1 or 0)
		end
	end
	return cnt
end
