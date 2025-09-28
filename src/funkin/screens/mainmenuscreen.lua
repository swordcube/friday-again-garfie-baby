--- @class funkin.screens.MainMenuScreen : funkin.screens.MusicBeatScreen
local MainMenuScreen = MusicBeatScreen:subclass("MainMenuScreen", ...)

function MainMenuScreen:enter()
    self.persistentUpdate = true

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.CYAN)
    self:addChild(self.camera)

    self.bgLayer = Parallax2D:new() --- @type comet.gfx.Parallax2D
    self.bgLayer.scrollFactor:set(0.1, 0.1)
    self.camera:addChild(self.bgLayer)

    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg"))
    self.bg.scale:set(1.175, 1.175)
    self.bg:screenCenter("xy")
    self.bgLayer:addChild(self.bg)
end

return MainMenuScreen