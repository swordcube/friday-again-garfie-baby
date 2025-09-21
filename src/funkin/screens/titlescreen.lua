--- @class funkin.screens.TitleScreen : comet.core.Screen
local TitleScreen = Screen:subclass("TitleScreen", ...)

function TitleScreen:enter()
    self.testCam = Camera:new() --- @type comet.gfx.Camera
    self.testCam:setBackgroundColor(Color.RED)
    self.testCam.size:set(1280, 720)

    local hueSet = comet.gfx:getShader(Paths.frag("shaders/hue_set"))
    hueSet:send("VALUE", 0.5)

    local hueOffset = comet.gfx:getShader(Paths.frag("shaders/hue_offset"))
    hueOffset:send("OFFSET", -0.5)

    local hueOffset2 = comet.gfx:getShader(Paths.frag("shaders/hue_offset"))
    hueOffset2:send("OFFSET", 0.2)

    local crt = comet.gfx:getShader(Paths.frag("shaders/crt"))
    crt:send("percent", 1.0)
    self.testCam:setShaders({hueSet, hueOffset, hueOffset2, crt})

    self:addChild(self.testCam)
end

return TitleScreen