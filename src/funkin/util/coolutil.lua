local fs = love.filesystem
local json = cometreq("lib.json") --- @type comet.lib.Json

--- @class funkin.util.CoolUtil
local CoolUtil = {}

function CoolUtil.playMusic(name, volume, looping)
    volume = volume or 1.0
    looping = looping or true

    comet.mixer.music:setSource(comet.mixer:getSource(Paths.music(name)))
    comet.mixer.music:setVolume(volume)
    comet.mixer.music:setLooping(looping)
    comet.mixer.music:play()

    local success, result = pcall(json.decode, fs.getContent(Paths.musicConfig(name)))
    if not success then
        FLog.error(("Failed to load config for music %s: %s"):format(name, result))
        return
    end
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    c:reset(result.timingPoints[1].b, result.timingPoints[1].ts)
    c:setupTimingPoints(result.timingPoints)
    c.music = comet.mixer.music
end

function CoolUtil.playMenuMusic(volume)
    CoolUtil.playMusic("freakyMenu", volume, true)
end

--- @param data string
--- @param sep  string?
function CoolUtil.parseCSV(data, sep)
    if not sep then
        sep = ","
    end
    local result = {}
    local lines = data:replace("\r", ""):split("\n")
    for i = 1, #lines do
        table.insert(result, lines[i]:split(sep))
    end
    return result
end

--- Parses a JSON file into a table and returns it
--- 
--- If an error occured while parsing, a nil table will be returned
--- alongside an error message string
--- 
--- @param data string A file path to a JSON or the JSON contents as a string
--- @return table, string
function CoolUtil.parseJson(data)
    -- i didn't feel like constantly requiring json so fuck you i'm putting it in CoolUtil
    if fs.exists(data) then
        data = fs.getContent(data)
    end
    local success, result = pcall(json.parse, data)
    if success then
        return result, nil
    end
    return nil, result
end

return CoolUtil