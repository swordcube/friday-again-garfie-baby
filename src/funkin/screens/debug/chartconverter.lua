--- @class funkin.screens.debug.ChartConverter : funkin.screens.MusicBeatScreen
local ChartConverter = MusicBeatScreen:subclass("ChartConverter", ...)

function ChartConverter:enter()
    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg_blue"))
    self.bg:screenCenter("xy")
    self.bg:setTint(0xFF4CAF50)
    self:addChild(self.bg)
end

function ChartConverter:update(dt)
    if self.controls.justPressed.BACK then
        self:destroy()
    end
end

return ChartConverter