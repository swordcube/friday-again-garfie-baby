--- @class funkin.screens.debug.UIDebugScreen : funkin.screens.MusicBeatScreen
local UIDebugScreen, super = MusicBeatScreen:extend("UIDebugScreen", ...)

function UIDebugScreen:enter()
    super.enter(self)
    self.persistentUpdate = true

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.GRAY)
    self:addChild(self.camera)

    self.test9slice = cometreq("ui.components.ui9sliceimage"):new() --- @type comet.ui.components.UI9SliceImage
    self.test9slice.size:set(500, 500)
    self.test9slice:screenCenter("xy")
    self.test9slice.rotation = 45
    self.camera:addChild(self.test9slice)

    self.menuBar = cometreq("ui.components.menubar"):new() --- @type comet.ui.components.MenuBar
    self.menuBar:addItems("left", {
        {
            text = "File",
        }
    })
    self.camera:addChild(self.menuBar)
end

function UIDebugScreen:input(e)
    if e.type == "text" then
        return
    end
    if self.controls.justPressed.BACK then
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
        self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
    end
end

function UIDebugScreen:update(dt)
    super.update(self, dt)
    self.test9slice:rotate(dt * 100)
end

return UIDebugScreen