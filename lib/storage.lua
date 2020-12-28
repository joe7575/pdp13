--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Persistent data storage

]]--


local storage = minetest.get_mod_storage()

pdp13.UdpData = minetest.deserialize(storage:get_string("UdpData")) or {}
pdp13.UIDCounter = storage:get_int("UIDCounter")

local function store_data()
	storage:set_string("UdpData", minetest.serialize(pdp13.UdpData))
	storage:set_int("UIDCounter", pdp13.UIDCounter)
	minetest.after(60*20, store_data)
end

minetest.register_on_shutdown(function()
	store_data()
end)

minetest.after(60*20 + 11, store_data)
