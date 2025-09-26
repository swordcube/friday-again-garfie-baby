--- @class funkin.screens.InitScreen : comet.core.Screen
local InitScreen = Screen:subclass("InitScreen", ...)

function InitScreen:enter()
    FLog = srcreq("funkin.util.flog") --- @type funkin.util.FLog
    
    Paths = srcreq("funkin.backend.assets.paths") --- @type funkin.backend.assets.Paths
    Paths.initAssetSystem()

    Conductor = srcreq("funkin.backend.plugins.conductor") --- @type funkin.backend.plugins.Conductor
    Conductor.instance = Conductor:new()
    Conductor.instance.dispatchToScreens = true
    comet.plugins:add(Conductor.instance)
    
    CoolUtil = srcreq("funkin.util.coolutil") --- @type funkin.util.CoolUtil

    srcreq("funkin.backend.crashhandler").init()
    srcreq("funkin.gfx.debugoverlay").init()

    if not love.filesystem.isFused() then
        local os = jit and jit.os or require("ffi").os
        if os == "Windows" then
            os = "win64"
        end
        _G.LOVEVLC_LIB_DIRECTORY = ("thirdparty/lovevlc/lib/%s"):format(os:lower())
    end
    require("thirdparty.lovevlc")
    comet.signals.onQuit:connect(function()
        require("thirdparty.lovevlc.util.handle").quit()
    end)
    Video = srcreq("funkin.gfx.video") --- @type funkin.gfx.Video

    if love.filesystem.exists("icon.png") then
        local icon = love.image.newImageData("icon.png")
        love.window.setIcon(icon)
        icon:release()
    end
    self:forceSwitchTo(srcreq("funkin.screens.titlescreen"):new())
end

return InitScreen