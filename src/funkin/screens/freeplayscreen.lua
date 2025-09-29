local AtlasTextMenu = srcreq("funkin.ui.atlastextmenu") --- @type funkin.ui.AtlasTextMenu

--- @class funkin.screens.FreeplayScreen : funkin.screens.MusicBeatScreen
local FreeplayScreen = MusicBeatScreen:subclass("FreeplayScreen", ...)

function FreeplayScreen:enter()
    self.persistentUpdate = true

    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg_blue"))
    self.bg:screenCenter("xy")
    self:addChild(self.bg)

    self.menu = AtlasTextMenu:new() --- @type funkin.ui.AtlasTextMenu
    for i = 1, 20 do
        self.menu:addItem("fuck " .. i)
    end
    self:addChild(self.menu)
end

function FreeplayScreen:update(dt)
    if self.controls.justPressed.BACK then
        self.persistentUpdate = false
        self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
    end
end

return FreeplayScreen