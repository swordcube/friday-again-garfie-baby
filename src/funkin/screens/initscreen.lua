--- @class funkin.screens.InitScreen : comet.core.Screen
local InitScreen = Screen:subclass("InitScreen", ...)

function InitScreen:enter()
    FLog = srcreq("funkin.util.flog") --- @type funkin.util.FLog
    
    Paths = srcreq("funkin.backend.assets.paths") --- @type funkin.backend.assets.Paths
    Paths.initAssetSystem()

    Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition
    Transition.setDefaultTransition(srcreq("funkin.ui.transition.gradientswipe"), true)

    MusicBeatScreen = srcreq("funkin.screens.musicbeatscreen") --- @type funkin.screens.MusicBeatScreen
    MusicBeatScreen.static.skipNextTransIn = true

    Controls = srcreq("funkin.backend.controls") --- @type funkin.backend.Controls
    Controls.static.instance = Controls:new()

    Conductor = srcreq("funkin.backend.plugins.conductor") --- @type funkin.backend.plugins.Conductor
    Conductor.instance = Conductor:new()
    Conductor.instance.dispatchToScreens = true
    comet.plugins:add(Conductor.instance)
    
    comet.plugins:add(srcreq("funkin.backend.plugins.debugbinds"):new())

    CoolUtil = srcreq("funkin.util.coolutil") --- @type funkin.util.CoolUtil
    AtlasText = srcreq("funkin.ui.atlastext") --- @type funkin.ui.AtlasText

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
    
    local handle = require("thirdparty.lovevlc.util.handle")
    handle.initasync()

    comet.signals.onQuit:connect(function()
        handle.quit()
    end)
    Video = srcreq("funkin.gfx.video") --- @type funkin.gfx.Video

    if love.filesystem.exists("icon.png") then
        local icon = love.image.newImageData("icon.png")
        love.window.setIcon(icon)
        icon:release()
    end
    self:forceSwitchTo(srcreq("funkin.screens.titlescreen"):new())
    MusicBeatScreen.static.skipNextTransIn = true
end

return InitScreen