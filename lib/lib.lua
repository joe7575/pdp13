--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	PDP-13 Helper Functions

]]--


-- ArrayRemove(t, function(t, i) 
--	  return t[i] ~= x 
-- end)
function pdp13.ArrayRemove(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function pdp13.get_node_lvm(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then
		return node
	end
	local vm = minetest.get_voxel_manip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	local idx = area:index(pos.x, pos.y, pos.z)
	node = {
		name = minetest.get_name_from_content_id(data[idx]),
		param2 = param2_data[idx]
	}
	return node
end

function pdp13.range(val, min, max)
	val = tonumber(val)
	if val < min then return min end
	if val > max then return max end
	return val
end

function table.extract(t, first ,last)
	local t2 = {}
	for i = first, last do
		t2[#t2+1] = t[i]
	end
	return t2
end

function pdp13.hex_dump(tbl)
	local t2 = {}
	for _,val in ipairs(tbl) do
		t2[#t2+1] = string.format("%04X", val)
	end
	return table.concat(t2, " ")
end

