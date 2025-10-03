local json = cometreq("lib.json") --- @type comet.lib.Json

--- @class funkin.gameplay.ui.UISkin
local UISkin = {}

--- @type table<string, funkin.gameplay.ui.UISkin.UISkinData>
UISkin._cache = {} --- @protected

function UISkin.clearCache()
    UISkin._cache = {}
end

function UISkin.get(name)
    if not UISkin._cache[name] then
        local success, result = pcall(CoolUtil.parseJson, Paths.json(("game/ui/%s/config"):format(name)))
        if success then
            UISkin._cache[name] = result
        else
            FLog.warn(("Failed to load UI skin config for %s: %s"):format(name, result))
            UISkin._cache[name] = {}
        end
    end
    return UISkin._cache[name]
end

return UISkin