local project = require("project")

--- @class funkin.backend.Options
local Options = {
    downscroll = false
}
-- this weird shit is done because the options class
-- above is for vscode documentation stuff
local defaultData = Options
Options = {}

function Options.init()
    Options._save = Save:new() --- @type comet.util.Save
    Options._save:bind("options", ("%s/%s"):format(project.author, project.identity))

    local doFlush = false
    for key, value in pairs(defaultData) do
        if Options._save.data[key] == nil then
            print(("Initializing %s to %s"):format(key, value))
            Options._save.data[key] = value
            doFlush = true
        end
    end
    if doFlush then
        Options._save:flush()
    end
end

function Options.save()
    Options._save:flush()
end

return setmetatable(Options, {
    __index = function(t, key)
        local s = rawget(t, "_save")
        if s then
            local sd = s.data
            if sd[key] ~= nil then
                return sd[key]
            end
        end
        return rawget(t, key)
    end,
    __newindex = function(t, key, value)
        local s = rawget(t, "_save")
        if s then
            local sd = s.data
            if sd[key] ~= nil then
                sd[key] = value
            else
                error("Cannot modify internals of Options class")
            end
        else
            rawset(t, key, value)
        end
    end
})