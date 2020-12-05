--[[

	PDP-13
	======

	Copyright (C) 2019 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information
	
	PDP-13 Editor

]]--

local INS = minetest.formspec_escape("[+]  ")
local DEL = minetest.formspec_escape("[–]  ")
local CHN = minetest.formspec_escape("[×]  ")

function pdp13.Editor:new(attr)
	local o = {
		sSize = attr.sSize or "size[10,9]",
		numTabs = attr.numTabs or 8,
		tabWidth = attr.tabWidth or 4,
		numLines = attr.numLines or 16,	-- max. visible
		maxLines = attr.maxLines or 16, -- max. scrollable
		textLines = {},
		editLine = "",
		startOffs = 0,
		currLine = 1,
		hisStr1 = "",
		hisStr2 = "",
	}
	setmetatable(o, self)
	self.__index = self
	return o
end


local function escape_text(s, columns)
	s = minetest.formspec_escape(s)

	local t = string.split(s, " # ", true, 8, true)
	local n = columns - #t
	for i = 1,n do
		t[#t+1] = ""
	end
	return table.concat(t, ",")
end

local function escape_lines(lines, columns)
	local t = {}
	local n = math.min(StartOffs + MAX_LINES, #lines)
	--print(StartOffs, n, CurrLine, #lines)
	for i = 1 + StartOffs, n do
		local s = lines[i] or ""
		t[#t+1] = escape_text(s, columns)
	end
	return table.concat(t, ",")
end


local function scrolldown(val)
	if val < MAX_LINES and val < #TextLines then
		return val + 1
	elseif val + StartOffs < #TextLines then
		StartOffs = StartOffs + 1
		return val
	end
	return val
end

local function scrollup(val)
	print("val/StartOffs", val, StartOffs)
	if val > 1 then
		return val - 1
	elseif val + StartOffs > 1 then
		StartOffs = StartOffs - 1
		return val
	end
	return val
end

local function formspec(tLines, sCmnd)
	local txt = escape_lines(tLines, 8)
	return "size[10,9]" ..
		"tablecolumns[text,width=4;text,width=4;text,width=4;text,width=4;text,width=4;text,width=4;text,width=4;text,width=4]" ..
		"tableoptions[color=#FDD30C]"..
		"table[0,0;9.8,7.4;screen;"..txt..";"..CurrLine.."]"..
		"container[0.2,7.5]"..
		"background[-0.2,0.2;10,1.64;techage_formspec_bg.png]"..
		"label[-0.1,0.1;"..HisStr2.."]"..
		"label[-0.1,0.5;"..HisStr1.."]"..
		"field[0.1,1.3;7.6,0.8;cmnd;;"..sCmnd.."]"..
		"field_close_on_enter[cmnd;false]"..
		"button[7.4,0.1;1.2,1;esc;ESC]"..
		"button[8.6,0.1;1.2,1;ins;INS]"..
		"button[7.4,0.9;1.2,1;rtn;RTN]"..
		"button[8.6,0.9;1.2,1;del;DEL]"..
		"container_end[]"
end
	
minetest.register_chatcommand("fs", {
    func = function(name, param)
		if not channel then
			print("register_chatcommand", "pdp13:terminal_"..name)
			channel = minetest.mod_channel_join("pdp13:terminal_"..name)
		end
		minetest.show_formspec(name, "pdp13:form", formspec(TextLines, EditLine))
    end
})

minetest.register_on_modchannel_message(function(channel_name, sender, message)
	print(channel_name, sender, message)	
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "pdp13:form" then return false end
	--print(dump(fields))
	if fields.screen then
		local evt = minetest.explode_table_event(fields.screen)
		if evt.type == "CHG" then
			CurrLine = evt.row
		end
	elseif fields.rtn == "RTN" or fields.key_enter == "true" then
		HisStr2 = HisStr1
		HisStr1 = CHN..minetest.formspec_escape(fields.cmnd)
		TextLines[CurrLine+StartOffs] = fields.cmnd
		if CurrLine+StartOffs == #TextLines then
			TextLines[#TextLines+1] = ""
		end
		CurrLine = scrolldown(CurrLine)
		--print(dump(channel))
		channel:send_all("Ich bin der Server")
	elseif fields.key_up == "true" then
		CurrLine = scrollup(CurrLine)
	elseif fields.key_down == "true" then
		CurrLine = scrolldown(CurrLine)
	elseif fields.ins == "INS" then
		CurrLine = CurrLine + 1
		table.insert(TextLines, CurrLine + StartOffs, "")
	elseif fields.del == "DEL" then
		HisStr2 = HisStr1
		HisStr1 = DEL..minetest.formspec_escape(TextLines[CurrLine + StartOffs] or "")
		table.remove(TextLines, CurrLine + StartOffs)
		if CurrLine + StartOffs > #TextLines then
			if CurrLine > 1 then
				CurrLine = CurrLine - 1
			elseif StartOffs > 1 then
				StartOffs = StartOffs - 1
			end
		end
	end
	EditLine = minetest.formspec_escape(TextLines[CurrLine+StartOffs] or "")
	minetest.show_formspec(player:get_player_name(), "pdp13:form", formspec(TextLines, EditLine))
    return true
end)