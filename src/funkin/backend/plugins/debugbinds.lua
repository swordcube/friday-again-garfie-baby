local Plugin = cometreq("core.plugin") --- @type comet.core.Plugin

--- @class funkin.backend.plugins.DebugBinds : comet.core.Plugin
local DebugBinds = Plugin:subclass("DebugBinds", ...)

function DebugBinds:input(_)
    if Controls.instance.justReleased.RELOAD then
        local current = ScreenManager.instance.current --- @type comet.core.Screen
        if comet.keys:isPressed("lshift") or comet.keys:isPressed("rshift") then
            current:forceSwitchTo(current._constructor and current._constructor() or require(current.class.rawPath):new())
        else
            current:switchTo(current._constructor or require(current.class.rawPath):new())
        end
    end
    if Controls.instance.justReleased.EMERGENCY then
        local current = ScreenManager.instance.current --- @type comet.core.Screen
        current:forceSwitchTo(srcreq("funkin.screens.mainmenuscreen"):new())
    end
end

return DebugBinds