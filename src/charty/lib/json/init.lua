local parent = ...
_G._JSON_PARENT = parent

local json = require(parent .. ".main")
json = require(parent .. ".jsonc")
json = require(parent .. ".beautify")
json = require(parent .. ".edit")
return json