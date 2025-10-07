--- @class funkin.gameplay.notes.NoteSkin
local NoteSkin = {}

--- @type table<string, funkin.gameplay.notes.NoteSkin.NoteSkinData>
NoteSkin._cache = {} --- @protected

function NoteSkin.clearCache()
    NoteSkin._cache = {}
end

function NoteSkin.get(name)
    if not NoteSkin._cache[name] then
        local success, result = pcall(CoolUtil.parseJson, Paths.json(("game/notes/%s/config"):format(name)))
        if success then
            NoteSkin._cache[name] = result
        else
            FLog.warn(("Failed to load note skin config for %s: %s"):format(name, result))
            NoteSkin._cache[name] = {}
        end
    end
    return NoteSkin._cache[name]
end

return NoteSkin