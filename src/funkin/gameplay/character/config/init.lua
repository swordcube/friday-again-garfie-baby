--- @class funkin.gameplay.character.Config
local Config = {}

--- @type table<string, funkin.gameplay.character.Config.ConfigData>
Config._cache = {} --- @protected

function Config.clearCache()
    Config._cache = {}
end

function Config.get(name)
    if not Config._cache[name] then
        local result, err = CoolUtil.parseJson(Paths.json(("game/characters/%s/config"):format(name)))
        if result then
            Config._cache[name] = result
        else
            FLog.warn(("Failed to load character config for %s: %s"):format(name, err))
            Config._cache[name] = {}
        end
    end
    return Config._cache[name]
end

return Config