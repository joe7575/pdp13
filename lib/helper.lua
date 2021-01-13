 --[[

	PDP-13
	======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	PDP-13 Helper functions

]]--

function pdp13.range(val, min, max, default)
	val = tonumber(val) or default
	val = math.max(val, min)
	val = math.min(val, max)
	return val
end

function pdp13.text2table(text)
	local t = {}
	text = text or ""
	for s in text:gmatch("[^\n]+") do
		table.insert(t, s)
	end
	return t
end

function pdp13.table_2rows(tbl, gap)
	local t = {}
	local size = math.floor((#tbl + 1) / 2) * 2
	for i = 1, size, 2 do
		table.insert(t, (tbl[i] or "")..gap..(tbl[i+1] or ""))
	end
	return t
end


