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

--- @class comet.tools.mathtools
local dummy = {}

local bit = require("bit")
local floor = math.floor

-- The value of *π / 2*.
math.halfpi = math.pi / 2

-- The value of *π * 2*.
math.pi2 = math.pi * 2

---
--- Returns if a number is NaN.
---
--- @param  n  number  The number to check.
---
function math.isNaN(n)
    return (n ~= n)
end

---
--- Returns the largest integral value smaller than or equal to `num` (rounding up).
---
--- @param  num  number  The number to round up.
--- 
function math.round(num)
    -- https://stackoverflow.com/questions/18313171/lua-rounding-numbers-and-then-truncate
    return floor(num + 0.49999999999999994)
end

---
--- Returns a random number within a range, similarly
--- to `math.random()`, but with more precision (more decimal numbers).
---
--- @param  low  number  The lower bound of the range.
--- @param  high number  The upper bound of the range.
--- 
--- @return number
---
function math.preciseRandom(low, high)
    return low + math.random()  * (high - low);
end

---
--- Round a decimal number to have reduced precision (less decimal numbers).
---
--- @param  num       number   The number to round.
--- @param  decimals  integer  Number of decimals the result should have.
---
function math.truncate(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.round(num * mult) / mult
end

---
--- Linearly interpolates one value to another.
---
--- @param  from   number  The value to interpolate from.
--- @param  to     number  The value to interpolate to.
--- @param  ratio  number  A multiplier to the amount of interpolation.
---
function math.lerp(from, to, ratio)
    return from + (to - from) * ratio
end

---
--- Converts a given numeric value into a human-readable string representation,
--- expressing the value in bytes, kilobytes (KB), megabytes (MB), gigabytes (GB), terabytes (TB), or petabytes (PB), 
--- based on its magnitude.
---
--- @param  x  number  The numeric value (in bytes) that you want to convert into a human-readable string.
---
function math.humanizeBytes(x)
    local intervals = {'b', 'kb', 'mb', 'gb', 'tb', 'pb'}
    local i = 1
    while x >= 1024 and i < #intervals do
        x = x / 1024
        i = i + 1
    end
    return math.truncate(x, 2) .. intervals[i]
end

--- 
--- Returns a clamped version of a specified number where
--- it never goes below `minimum` or above `maximum`.
---
--- @param  value    number   The number to clamp.
--- @param  minimum  number?  The minimum value that `value` can go-to.
--- @param  maximum  number?  The maximum value that `value` can go-to.
---
function math.clamp(value, minimum, maximum)
    local lowerBound = (minimum and value < minimum) and minimum or value
	return (maximum and lowerBound > maximum) and maximum or lowerBound
end

--- 
--- Returns a wrapped version of a specified number where
--- it wraps around to `minimum` when it exceeds `maximum` and
--- wraps around to `maximum` when it goes below `minimum`.
---
--- @param  value    number   The number to wrap.
--- @param  minimum  number   The minimum value that `value` can go-to.
--- @param  maximum  number   The maximum value that `value` can go-to.
---
function math.wrap(value, minimum, maximum)
    local range = maximum - minimum + 1
    if value < minimum then
        value = value + range * math.round((minimum - value) / range + 1)
    end
    return minimum + (value - minimum) % range
end

---
--- Formats a given number as a string representing money.
---
--- @param  amount        number     The number to format.
--- @param  showDecimal   boolean?   Whether or not to include the decimal part of the number when formatting. (default: true)
--- @param  englishStyle  boolean?   Whether or not to use english style formatting (i.e. use `.` for the decimal part and `,` for the thousands separator). (default: true)
---
--- @return string  str  The formatted string.
---
function math.formatMoney(amount, showDecimal, englishStyle)
    if showDecimal == nil then
        showDecimal = true
    end
    if englishStyle == nil then
        englishStyle = true
    end
    local isNegative = amount < 0
    amount = math.abs(amount)

    local str = ""
    local comma = ""
    local whole = math.floor(amount)

    while whole > 0 do
        if #str > 0 and #comma <= 0 then
            comma = englishStyle and "," or "."
        end
        local zeroes = ""
        local helper = whole - math.floor(whole / 1000) * 1000
        whole = math.floor(whole / 1000)
        if whole > 0 then
            if helper < 100 then
                zeroes = zeroes .. "0"
            end
            if helper < 10 then
                zeroes = zeroes .. "0"
            end
        end
        str = zeroes .. helper .. comma .. str
    end

    if str == "" then
        str = "0"
    end
    if showDecimal then
        local decimal = math.floor(amount * 100) - math.floor(amount) * 100
        str = str .. (englishStyle and "." or ",")
        if decimal < 10 then
            str = str .. "0"
        end
        str = str .. decimal
    end
    if isNegative then
        str = "-" .. str
    end
    return str
end

---
--- Returns the sign of a given number.
--- 
--- @param  value  number  The number to get the sign of.
--- @return number
---
function math.sign(value)
    return value < 0 and -1.0 or 1.0
end

---
--- A faster but slightly less accurate version of `math.sin`
--- 
--- About 2-6 times faster with < 0.05% average margin of error
--- 
--- @param  n  number  The angle in radians.
--- @return number
--- 
function math.fastsin(n)
    n = n * 0.3183098862 -- divide by pi to normalize

    -- bound between -1 and 1
    if n > 1 then
        n = n - bit.lshift(bit.rshift(math.ceil(n), 1), 1)
    elseif n < -1 then
        n = n + bit.lshift(bit.rshift(math.ceil(-n), 1), 1)
    end

    -- this approx only works for -pi <= rads <= pi, but it's quite accurate in this region
    if n > 0 then
        return n * (3.1 + n * (0.5 + n * (-7.2 + n * 3.6)))
    end
    return n * (3.1 - n * (0.5 + n * (7.2 + n * 3.6)))
end

---
--- A faster but slightly less accurate version of `math.cos`
--- 
--- About 2-6 times faster with < 0.05% average margin of error
--- 
--- @param  n  number  The angle in radians.
--- @return number
--- 
function math.fastcos(n)
    return math.fastsin(n + math.halfpi)
end