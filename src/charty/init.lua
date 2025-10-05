local parent = ...
_G._CHARTY_PARENT = parent

--- @class charty.Charty
local Charty = {
    _formats = {
        ["fnf_legacy"] = require(parent .. ".formats.fnf_legacy"),
        ["fnf_vslice"] = require(parent .. ".formats.fnf_vslice"),
        ["fnf_psych"] = require(parent .. ".formats.fnf_psych"),
        ["fnf_psych_1x"] = require(parent .. ".formats.fnf_psych_1x"),
        ["fnf_codename"] = require(parent .. ".formats.fnf_codename"),
        ["fnf_garfie_baby"] = require(parent .. ".formats.fnf_garfie_baby"),
        ["guitar_hero"] = require(parent .. ".formats.guitar_hero"),
        ["osu_mania"] = require(parent .. ".formats.osu_mania"),
        ["quaver"] = require(parent .. ".formats.quaver"),
        ["stepmania"] = require(parent .. ".formats.stepmania"),
    }
}

function Charty.registerFormat(id, format)
    Charty._formats[id] = format
end

function Charty.getFormat(id)
    if not Charty._formats[id] then
        local success, result = pcall(require, (parent .. ".formats.%s"):format(id))
        if success then
            Charty._formats[id] = result
        else
            print(("Failed to load format %s: %s"):format(id, result))
            Charty._formats[id] = nil
        end
    end
    return Charty._formats[id]
end

return Charty