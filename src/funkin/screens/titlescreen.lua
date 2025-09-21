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

    self.gf = AnimatedImage:new(comet.getDesiredWidth() * 0.4, comet.getDesiredHeight() * 0.07) --- @type comet.gfx.AnimatedImage
    self.gf:setFrameCollection(Paths.getSparrowAtlas("menus/title/gf"))
    self.gf:addAnimationByIndices("danceLeft", "gfDance", table.numberList(1, 15), 24, false)
    self.gf:addAnimationByIndices("danceRight", "gfDance", table.numberList(16, 31), 24, false)
    self.gf:playAnimation("danceLeft")
    self.gf.centered = false
    self.testCam:addChild(self.gf)

    self:addChild(self.testCam)
end

function TitleScreen:beatHit(beat)
    if beat % 2 == 0 then
        self.gf:playAnimation("danceRight")
    else
        self.gf:playAnimation("danceLeft")
    end
end

return TitleScreen