--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 History buffer

]]--

local BUFFER_DEPTH = 10

function pdp13.historybuffer_add(pos, s)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}
	
	if #s > 2 then
		table.insert(mem.hisbuf, s)
		if #mem.hisbuf > BUFFER_DEPTH then
			table.remove(mem.hisbuf, 1)
		end
		mem.hisbuf_idx = #mem.hisbuf + 1
	end
end

function pdp13.historybuffer_priv(pos)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}
	mem.hisbuf_idx = mem.hisbuf_idx or 1
	
	mem.hisbuf_idx = math.max(1, mem.hisbuf_idx - 1)
	return mem.hisbuf[mem.hisbuf_idx]
end

function pdp13.historybuffer_next(pos)
	local mem = techage.get_mem(pos)
	mem.hisbuf = mem.hisbuf or {}
	mem.hisbuf_idx = mem.hisbuf_idx or 1
	
	mem.hisbuf_idx = math.min(#mem.hisbuf, mem.hisbuf_idx + 1)
	return mem.hisbuf[mem.hisbuf_idx]
end