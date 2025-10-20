local fs = love.filesystem
local ScriptPack = srcreq("funkin.scripting.scriptpack") --- @type funkin.scripting.ScriptPack

--- @class funkin.gameplay.events.behaviors.EventBehavior : comet.util.Class
local EventBehavior = Class("EventBehavior", ...)

function EventBehavior:__init__(name)
    self.name = name

    self.scripts = ScriptPack:new() --- @type funkin.scripting.ScriptPack
    self.scripts:linkObject(PlayScreen.instance)

    for loader in range(table.unpack(Paths._registeredAssetLoaders)) do
        local scriptPath = Paths.script(("game/events/%s"):format(name), loader.id, false)
        if fs.isFile(scriptPath) then
            self.scripts:add(Script:new(scriptPath))
        end
    end
    self.scripts:call("new")
end

function EventBehavior:execute(time, params)
    if self.scripts then
        self.scripts:call("onExecute", time, params)
        self.scripts:call("onExecutePost", time, params)
    end
end

function EventBehavior:onQueue(time, params)
    if self.scripts then
        self.scripts:call("onQueue", time, params)
        self.scripts:call("onQueuePost", time, params)
    end
end

function EventBehavior:destroy()
    if self.scripts then
        self.scripts:close()
        self.scripts = nil
    end
end

return EventBehavior