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

--- @class comet.tools.tabletools
local dummy = {}

local _table = table -- Faster access from local than global

-- Backwards compatibility
table.pack = table.pack or function(...) return { n = select("#", ...), ... } end
table.unpack = table.unpack or unpack

---
--- Returns whether or not a table contains any
--- specified element.
---
--- @param table   table  The table to check.
--- @param element any    The element to check.
---
--- @return boolean
---
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

---
--- Returns the index of an element in a table.
--- Returns `-1` if the element couldn't be found in the table.
---
--- @param table   table  The table to check.
--- @param element any    The element to check.
---
--- @return integer
---
function table.indexOf(table, element)
    for i = 1, #table do
        if table[i] == element then
            return i
        end
    end
    return -1
end

---
--- Makes a copy of a table.
---
--- @param t     table    The table to make a copy of.
--- @param deep? boolean  Whether or not all nested subtables should be deeply copied. If not, a shallow copy is performed, where only the top-level elements are copied.
--- @param seen? table    A tracking table to avoid infinite loops when dealing with circular references or shared references in nested tables. This parameter is primarily used internally and can be omitted when calling the function.
---
--- @return table|nil
---
function table.copy(t, deep, seen)
    seen = seen or {}
    if t == nil then return nil end
    if seen[t] then return seen[t] end

    local nt = {}
    for k, v in pairs(t) do
        if deep and type(v) == 'table' then
            nt[k] = table.copy(v, deep, seen)
        else
            nt[k] = v
        end
    end
    setmetatable(nt, table.copy(getmetatable(t), deep, seen))
    seen[t] = nt
    return nt
end

---
--- Creates a new table by filtering the elements of `t`
--- based on the result of the filtering function `func()`.
---
--- It includes only those elements for which func returns a truthy value.
---
--- @param t    table     The table to filter.
--- @param func function  The function to filter the table with.
---
--- @return table
---
function table.filter(t, func)
    local filtered = {}
    for _, value in ipairs(t) do
        if func(value) then
            _table.insert(filtered, value)
        end
    end
    return filtered
end

---
--- Creates a new string based on the elements of the table `t`,
--- separated by the string `sep`.
---
--- @param t    table   The table you want to make a string representation of.
--- @param sep? string  The separator between each item of the table in the final string.
---
--- @return string
---
function table.join(t, sep)
    if sep == nil then
        sep = ""
    end

    local tl = #t
    local result = ""

    for i, value in ipairs(t) do
        result = result .. tostring(value)
        if i < tl then
            result = result .. sep
        end
    end

    return result
end

---
---dynamically set a value in a multidimensional table based off of a list   
---author: https://stackoverflow.com/questions/67801776/writing-to-dynamic-multidimensional-table-via-path
---
---@param list table
---@param keys table<string|number>
---
---@param value any
---
function table.set(list, keys, value)
	local lastKey = nil

	for _, key in ipairs(keys) do
		key, lastKey = lastKey, key

		if key == nil then goto continue end

		local parentList = list

		list = rawget(parentList, key)

		if list == nil then
			list = {}
			rawset(parentList, key, list)
		end

		if type(list) ~= "table" then error("Unexpected subtable", 2) end

		::continue::
	end

	rawset(list, lastKey, value)
end

---
---dynamically get a value in a multidimensional table based off of a list   
---author: https://stackoverflow.com/questions/67801776/writing-to-dynamic-multidimensional-table-via-path
---
---@param list table
---@param keys table<string|number>
---
---@return any
---
function table.get(list, keys)
	for index, key in ipairs(keys) do
	   if list == nil then return nil end

	   if type(list) ~= "table" then error("Unexpected subtable", 2) end

	   list = rawget(list, key)
	end

	return list
end

---
--- Removes a specific item from a table.
---
--- @param t     table  The table to remove the item from.
--- @param item  any    The item to remove from the table.
--- 
--- @return any
---
function table.removeItem(t, item)
	return _table.remove(t, _table.indexOf(t, item))
end

---
--- Removes duplicate elements from a table.
--- This will return a *new* table with *only* the unique elements.
--- 
--- @param  t  table  The table to remove duplicates from.
--- 
--- @return table
---
function table.removeDuplicates(t)
    local hash = {}
    local res = {}
    for _, v in ipairs(t) do
        if not hash[v] then
            res[#res+1] = v
            hash[v] = true
        end
    end
    return res
end

function table.numberList(beginNumber, endNumber, inc)
    local t = {}
    for i = beginNumber, endNumber, inc or 1 do
        t[#t + 1] = i
    end
    return t
end