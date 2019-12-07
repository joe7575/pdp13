--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Owner management

]]--

-- for lazy programmers
local P2P = minetest.string_to_pos
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local M = minetest.get_meta
local N = function(pos) return minetest.get_node(pos).name end

------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local Version = minetest.deserialize(storage:get_string("Version")) or 1
local Owners  = minetest.deserialize(storage:get_string("Owners")) or {}

local function update_mod_storage()
	minetest.log("action", "[TechAge] Store data...")
	storage:set_string("Version", minetest.serialize(Version))
	storage:set_string("Owners", minetest.serialize(Owners))
	-- store data each hour
	minetest.after(60*59, update_mod_storage)
	minetest.log("action", "[pdp13] Data stored")
end

-- delete invalid entries
minetest.after(2, function()
	for owner, items in pairs(Owners) do
		pdp13.ArrayRemove(items, function(t,i)
			local node = pdp13.get_node_lvm(t[i])
			return node.name ~= "pdp13:cpu1" and node.name ~= "pdp13:cpu1_on"
		end)
	end
end)

-- store data after one hour
minetest.after(50*59, update_mod_storage)


function pdp13.add_to_owner_list(owner, pos)
	print("add_to_owner_list")
	Owners[owner] = Owners[owner] or {}
	Owners[owner][#Owners[owner]+1] = pos
end

function pdp13.remove_from_owner_list(owner, pos)
	print("remove_from_owner_list")
	if Owners[owner] then
		pdp13.ArrayRemove(Owners[owner], function(t,i)
			return t[i].pos and pos and vector.equals(t[i].pos, pos)
		end)
	end
end



minetest.register_on_joinplayer(function(player)
	local owner = player:get_player_name()
	if Owners[owner] then
		for _,pos in ipairs(Owners[owner]) do
			pdp13.vm_restore(owner, pos)
			pdp13.vm_resume(owner, pos)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local owner = player:get_player_name()
	if Owners[owner] then
		for _,pos in ipairs(Owners[owner]) do
			pdp13.vm_store(owner, pos)
			pdp13.vm_suspend(owner, pos)
		end
	end
end)

minetest.register_on_shutdown(function()
	for _,player in ipairs(minetest.get_connected_players()) do
		local owner = player:get_player_name()
		if Owners[owner] then
			for _,pos in ipairs(Owners[owner]) do
				pdp13.vm_store(owner, pos)
			end
		end
	end
	update_mod_storage()
end)
