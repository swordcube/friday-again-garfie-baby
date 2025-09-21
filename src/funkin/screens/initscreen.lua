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

    srcreq("funkin.gfx.debugoverlay").init()
    self:forceSwitchTo(srcreq("funkin.screens.titlescreen"):new())
end

return InitScreen