--- @class funkin.screens.InitScreen : comet.core.Screen
local InitScreen = Screen:subclass("InitScreen", ...)

function InitScreen:enter()
    FLog = srcreq("funkin.util.flog") --- @type funkin.util.FLog
    FLog.init()

    Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition
    Transition.setDefaultTransition(srcreq("funkin.ui.transition.gradientswipe"), true)

    MusicBeatScreen = srcreq("funkin.screens.musicbeatscreen") --- @type funkin.screens.MusicBeatScreen
    MusicBeatScreen.static.skipNextTransIn = true

    MusicBeatSubScreen = srcreq("funkin.screens.musicbeatsubscreen") --- @type funkin.screens.MusicBeatSubScreen

    CoolUtil = srcreq("funkin.util.coolutil") --- @type funkin.util.CoolUtil
    AtlasText = srcreq("funkin.ui.atlastext") --- @type funkin.ui.AtlasText
    PlayScreen = srcreq("funkin.screens.playscreen") --- @type funkin.screens.PlayScreen

    Paths = srcreq("funkin.backend.assets.paths") --- @type funkin.backend.assets.Paths
    Paths.initAssetSystem()

    Options = srcreq("funkin.backend.options") --- @type funkin.backend.Options
    Options.init()

    Controls = srcreq("funkin.backend.controls") --- @type funkin.backend.Controls
    Controls.static.instance = Controls:new()

    Conductor = srcreq("funkin.backend.plugins.conductor") --- @type funkin.backend.plugins.Conductor
    Conductor.instance = Conductor:new()
    Conductor.instance.dispatchToScreens = true
    comet.plugins:add(Conductor.instance)
    
    comet.plugins:add(srcreq("funkin.backend.plugins.debugbinds"):new())

    srcreq("funkin.backend.crashhandler").init()
    srcreq("funkin.gfx.debugoverlay").init()

    -- macOS is currently unsupported, along with Android and iOS
    -- On those platforms ogv videos will be required
    local supportedOSes = {"Windows", "Linux"}
    if table.contains(supportedOSes, love.system.getOS()) then
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
    end
    Video = srcreq("funkin.gfx.video") --- @type funkin.gfx.Video
    Script = srcreq("funkin.scripting.script") --- @type funkin.scripting.Script

    if love.filesystem.exists("icon.png") then
        local icon = love.image.newImageData("icon.png")
        love.window.setIcon(icon)
        icon:release()
    end
    comet.mixer:setMasterVolume(0.3)

    if table.contains(arg, "--gameplay") then
        self:forceSwitchTo(srcreq("funkin.screens.playscreen"):new({
            song = "lit-up-bf-mix",
            difficulty = "hard"
        }))
    else
        self:forceSwitchTo(srcreq("funkin.screens.titlescreen"):new())
    end
    
    MusicBeatScreen.static.skipNextTransIn = true
end

return InitScreen