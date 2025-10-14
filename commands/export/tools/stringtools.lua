--[[
    chip.lua: a simple 2D game framework built off of Love2D
    Copyright (C) 2024  swordcube

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

--- @class comet.tools.stringtools
local dummy = {}

local _string = string -- Faster access from local than global
local table = table -- Faster access from local than global

function string.table(tbl, indent, been)
	if type(tbl) ~= "table" then return tostring(tbl) end
	been = been or {}
	if been[tbl] then return "{ recursive table }" end
	been[tbl] = true
	indent = indent or 0

	local _str = "{\n"
	local pad = string.rep("  ", indent + 1)

	for k, v in pairs(tbl) do
		local key = tostring(k)
		local value = tostring(v)
		if type(v) == "table" then
			value = string.table(v, indent + 1, been)
		end
		if type(v) == "string" then value = "\"" .. tostring(v) .. "\"" end
		_str = _str .. pad .. key .. " = " .. value .. ",\n"
	end
	_str = _str .. string.rep("  ", indent) .. "}"
	local name = ""
	if tbl._name then name = "(" .. tostring(tbl._name) .. ")" end
	return tostring(tbl) .. name .. " " .. _str
end

---
--- Splits a `string` at each occurrence of `delimiter`.
---
--- @param self      string  The string to split.
--- @param delimiter string  The delimiter to split the string by.
--- @return string[]
---
function string.split(self, delimiter)
    local result = {}
    if #delimiter == 0 then
        for i = 1, #self do
            table.insert(result, self:sub(i, i))
        end
    else
        local regex = ("([^%s]+)"):format(delimiter)
        for each in self:gmatch(regex) do
            table.insert(result, each)
        end
    end
    return result
end

---
--- Trims the left and right ends of this `string`
--- to remove invalid characters.
---
--- @param  self  string  The string to trim.
---
function string.trim(self)
    return self:gsub("^%s*(.-)%s*$", "%1")
end

---
--- Returns if the contents of a `string` contains the
--- contents of another `string`. 
---
--- @param self    string  The string to check.
--- @param value  string  What `string` should contain.
---
function string.contains(self, value)
    return self:find(value, 1, true) ~= nil
end

---
--- Returns the index of the first occurrence of `value` in `str`.
---
--- @param self    string  The string to search.
--- @param value  string  What to search for.
---
--- @return integer
---
function string.indexOf(self, value)
    local idx = self:find(value, 1, true)
    return idx or -1
end


---
--- Returns if the contents of a `string` starts with the
--- contents of another `string`. 
---
--- @param self   string  The string to check.
--- @param start  string  What `string` should start with.
---
function string.startsWith(self, start)
    return self:sub(1, #start) == start
end

--- Returns if the contents of a `string` ends with the
--- contents of another `string`. 
---
--- @param self    string  The string to check.
--- @param ending string  What `string` should end with.
---
function string.endsWith(self, ending)
    return ending == "" or self:sub(-#ending) == ending
end

---
--- Gets the last occurrence of `sub` in the string of `str`
--- and returns the index of it.
---
--- @param self  string  The main string in which you want to find the last index of the `sub`.
--- @param sub   string  The substring for which you want to find the last index in the `str`.
---
function string.lastIndexOf(self, sub)
    local subStringLength = #sub
    local lastIndex = -1

    for i = 1, #self - subStringLength + 1 do
        local currentSubstring = self:sub(i, i + subStringLength - 1)
        if currentSubstring == sub then
            lastIndex = i
        end
    end

    return lastIndex
end

--- Replaces all occurrences of `from` in a `string` with
--- the contents of `to`.
---
--- @param self    string  The string to check.
--- @param from   string  The content to be replaced with `to`.
--- @param to     string  The content to replace `from` with.
---
function string.replace(self, from, to)
    local s, _ = self:gsub(from:gsub('([%^%$%(%)%%%.%[%]%*%+%-%q?])', '%%%1'), to)
    return s
end

---
--- Inserts any given string into another `string`
--- starting at a given character position.
---
--- @param self    string   The string to have content inserted into.
--- @param pos    integer  The character position to insert the new content.
--- @param text   string   The content to insert.
---
function string.insert(self, pos, text)
    return self:sub(1, pos - 1) .. text .. self:sub(pos)
end

---
--- Returns the character of a given string
--- at a certain position of said string.
---
--- @param self string   The string to get this character from.
--- @param pos integer  The position of the character to get.
---
function string.charAt(self, pos)
    return _string.sub(self, pos, pos)
end

---
---
--- Similar to `string.charAt()` but it returns the raw character
--- code of the returned character.
---
--- @param self string   The string to get this character code from.
--- @param pos integer  The position of the character code to get.
---
function string.charCodeAt(self, pos)
    return _string.byte(_string.charAt(self, pos))
end

--- Pads a given string with a given character
--- (default: whitespace) up to a certain length
--- on the left side of the string.
---
--- @param  self    string   The string to pad.
--- @param  length  integer  The length to pad the string to.
--- @param  char    string   The character to pad the string with. (default: whitespace)
---
function string.lpad(self, length, char)
    return _string.rep(char or ' ', length - #self) .. self
end

--- Pads a given string with a given character
--- (default: whitespace) up to a certain length
--- on the right side of the string.
---
--- @param  self    string   The string to pad.
--- @param  length  integer  The length to pad the string to.
--- @param  char    string   The character to pad the string with. (default: whitespace)
---
function string.rpad(self, length, char)
    return self .. _string.rep(char or ' ', length - #self)
end

---
--- Converts a given string to title case.
--- 
--- @param  self  string  The string to convert to title case.
---
function string.title(self)
    local split = string.split(self, " ")
    if not split then
        split = {self}
    end
    for i = 1, #split do
        local str = split[i] --- @type string
        if #str > 0 then
            split[i] = str:charAt(1):upper() .. str:sub(2)
        end
    end
    return table.concat(split, " ")
end