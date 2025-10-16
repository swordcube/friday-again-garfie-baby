local fs = love.filesystem

--- @class funkin.gameplay.events.behaviors.EventBehavior : comet.util.Class
local EventBehavior = Class("EventBehavior", ...)

function EventBehavior:__init__(name)
    self.name = name

    local scriptPath = Paths.script(("game/events/%s"):format(name), nil, false)
    if fs.isFile(scriptPath) then
        self.script = Script:new(scriptPath) --- @type funkin.scripting.Script
        self.script:linkObject(PlayScreen.instance)
    end
end

function EventBehavior:execute(time, params)
    if self.script then
        self.script:call("onExecute", time, params)
    end
end

function EventBehavior:destroy()
    if self.script then
        self.script:close()
        self.script = nil
    end
end

return EventBehavior