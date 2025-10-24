local EventBehavior = srcreq("funkin.gameplay.events.behaviors.eventbehavior") --- @type funkin.gameplay.events.behaviors.EventBehavior

--- @class funkin.gameplay.events.behaviors.CameraPanBehavior : funkin.gameplay.events.behaviors.EventBehavior
local CameraPanBehavior, super = EventBehavior:extend("CameraPanBehavior", ...)

function CameraPanBehavior:execute(time, params)
    if self.scripts then
        self.scripts:call("onExecute", time, params)
    end
    local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
    if game then
        local char = params.array and params.array[1] or params.char
        game.curCameraTarget = char + 1
    end
    if self.scripts then
        self.scripts:call("onExecutePost", time, params)
    end
end

function CameraPanBehavior:onQueue(time, params)
    if self.scripts then
        self.scripts:call("onQueue", time, params)
    end
    if time <= 20 then
        local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
        if game then
            local char = params.array and params.array[1] or params.char
            game.curCameraTarget = char + 1
        end
    end
    if self.scripts then
        self.scripts:call("onQueuePost", time, params)
    end
end

return CameraPanBehavior