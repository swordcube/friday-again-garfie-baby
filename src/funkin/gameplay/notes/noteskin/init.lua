--- @class funkin.gameplay.notes.NoteSkin
local NoteSkin = {}

--- @type table<string, funkin.gameplay.notes.NoteSkin.NoteSkinData>
NoteSkin._cache = {} --- @protected

function NoteSkin.clearCache()
    NoteSkin._cache = {}
end

function NoteSkin.get(name)
    if not NoteSkin._cache[name] then
        local result, err = CoolUtil.parseJson(Paths.json(("game/notes/%s/config"):format(name)))
        if result then
            NoteSkin._cache[name] = result
        else
            FLog.warn(("Failed to load note skin config for %s: %s"):format(name, err))
            NoteSkin._cache[name] = {}
        end
    end
    return NoteSkin._cache[name]
end

return NoteSkin