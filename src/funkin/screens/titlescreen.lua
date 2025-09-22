--- @class funkin.screens.TitleScreen : comet.core.Screen
local TitleScreen = Screen:subclass("TitleScreen", ...)

function TitleScreen:enter()
    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic()
    end
    self.testCam = Camera:new() --- @type comet.gfx.Camera
    self.testCam.size:set(1280, 720)

    self.gf = AnimatedImage:new(comet.getDesiredWidth() * 0.4, comet.getDesiredHeight() * 0.07) --- @type comet.gfx.AnimatedImage
    self.gf:setFrameCollection(Paths.getSparrowAtlas("menus/title/gf"))
    self.gf:addAnimationByIndices("danceLeft", "gfDance", table.numberList(1, 15), 24, false)
    self.gf:addAnimationByIndices("danceRight", "gfDance", table.numberList(16, 31), 24, false)
    self.gf:playAnimation("danceLeft")
    self.gf.centered = false
    self.testCam:addChild(self.gf)

    self.logo = AnimatedImage:new(-150, -100) --- @type comet.gfx.AnimatedImage
    self.logo:setFrameCollection(Paths.getSparrowAtlas("menus/title/logo"))
    self.logo:addAnimation("idle", "logo bumpin", 24, false)
    self.logo:playAnimation("idle")
    self.logo.centered = false
    self.testCam:addChild(self.logo)

    self:addChild(self.testCam)
end

function TitleScreen:beatHit(beat)
    if beat % 2 == 0 then
        self.gf:playAnimation("danceRight")
    else
        self.gf:playAnimation("danceLeft")
    end
    self.logo:playAnimation("idle", true)
end

return TitleScreen