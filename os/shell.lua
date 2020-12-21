--[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Monitor extension for Terminal mode

]]--

-- copy memory
Commands["ed"] = function(pos, mem, cmd, rest)
	mem.mstate = nil
	local words = string.split(rest, " ", false, 2)
	if #words == 3 then
		local src_addr = pdp13.string_to_number(words[1])
		local dst_addr = pdp13.string_to_number(words[2])
		local number = pdp13.string_to_number(words[3])
		if src_addr and dst_addr and number then
			local tbl = vm16.read_mem(pos, src_addr, number)
			vm16.write_mem(pos, dst_addr, tbl)
			return {"memory copied"}
		end
	end
	return {"error!"}
end
