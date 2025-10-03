-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

local path = select(1, ...)

--- @class funkin.gfx.RuntimeTextureAtlas
local RuntimeTextureAtlas = {
    newFixedSize = require(... .. ".fixedsize").new,
    newDynamicSize = require(... .. ".dynamicsize").new
}
return RuntimeTextureAtlas