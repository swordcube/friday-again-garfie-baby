local UISkin = srcreq("funkin.gameplay.ui.uiskin") --- @type funkin.gameplay.ui.UISkin
local RuntimeTextureAtlas = srcreq("funkin.gfx.rta") --- @type funkin.gfx.RuntimeTextureAtlas
local AnimatedVelocityImage = srcreq("funkin.gfx.animatedvelocityimage") --- @type funkin.gfx.AnimatedVelocityImage

--- @class funkin.gameplay.ui.ScoreDisplay : comet.gfx.Object2D
local ScoreDisplay, super = Object2D:extend("ScoreDisplay", ...)

local math, lmath = math, love.math

function ScoreDisplay:__init__(x, y)
    super.__init__(self, x, y)

    self._skin = nil --- @type string
    self._skinData = nil --- @type funkin.gameplay.ui.UISkin.UISkinData

    self._scoreAtlas = nil --- @type comet.gfx.FrameCollection
end

function ScoreDisplay:loadSkin(newSkin)
    if self._skin == newSkin then
        return
    end
    self._skin = newSkin or "funkin"
    self._skinData = UISkin.get(self._skin)

    if not self._skinData.rating then
        self._skin = "funkin"
        self._skinData = UISkin.get("funkin")
    end
    -- combine the rating and combo textures into one singular atlas for batching 🤑🤑🤑🤑🤑
    local ta = RuntimeTextureAtlas.newDynamicSize()
    for rating, data in pairs(self._skinData.rating.animation) do
        ta:add(love.graphics.newImage(Paths.image(("game/ui/%s/%s/%s"):format(self._skin, self._skinData.rating.folder, data.texture or rating))), rating)
    end
    for digit, data in pairs(self._skinData.combo.animation) do
        ta:add(love.graphics.newImage(Paths.image(("game/ui/%s/%s/%s"):format(self._skin, self._skinData.combo.folder, data.texture or digit))), digit)
    end
    ta:bake("width")

    if self._scoreAtlas then
        self._scoreAtlas:dereference()
        self._scoreAtlas = nil
    end
    self._scoreAtlas = ta:toFrameCollection() --- @type comet.gfx.FrameCollection
    self._scoreAtlas:reference()
end

function ScoreDisplay:showRating(rating)
    local spr = self:recycle(AnimatedVelocityImage) --- @type funkin.gfx.AnimatedVelocityImage
    spr:setFrameCollection(self._scoreAtlas)
    spr:addAnimationByName("r", rating, 0, false)
    spr:playAnimation("r", true)
    spr.acceleration.y = 550
    spr.velocity.x = math.floor(lmath.random(0, -10))
    spr.velocity.y = math.floor(lmath.random(-140, -175))
    spr:setTint(Color.WHITE)
    spr.alpha = 1

    spr.scale:set(self._skinData.rating.scale, self._skinData.rating.scale)
    spr.position:set((spr:getWidth() * 0.5) - 40, -60)

    spr.scale:set(self._skinData.rating.scale * 0.95, self._skinData.rating.scale * 0.95)
    self:moveChild(spr, self:getChildCount())

    local t = Tween:new() --- @type comet.gfx.Tween
    t:target({target = spr.scale, properties = {x = self._skinData.rating.scale, y = self._skinData.rating.scale}})
    t:start({duration = 0.2})

    local t = Tween:new() --- @type comet.gfx.Tween
    t.onComplete:connect(function()
        spr:kill()
    end)
    t:target({target = spr, properties = {alpha = 0}})
    t:start({duration = 0.2, delay = Conductor.instance:getCurrentBeatLength() * 0.001})
end

function ScoreDisplay:showCombo(combo, miss)
    if miss then
        combo = -math.abs(combo)
    end
    local comboStr = tostring(math.abs(combo))
    while #comboStr < 3 do
        comboStr = "0" .. comboStr
    end
    if combo < 0 then
        comboStr = "-" .. comboStr
    end
    for i = 1, #comboStr do
        local char = string.charAt(comboStr, i)
        if char == "-" then
            char = "minus"
        end
        local spr = self:recycle(AnimatedVelocityImage) --- @type funkin.gfx.AnimatedVelocityImage
        spr:setFrameCollection(self._scoreAtlas)
        spr:addAnimationByName("c", char, 0, false)
        spr:playAnimation("c", true)
        spr.acceleration.y = math.floor(lmath.random(200, 300))
        spr.velocity.x = lmath.random(-5, 5)
        spr.velocity.y = math.floor(lmath.random(-140, -160))
        
        spr.scale:set(self._skinData.combo.scale, self._skinData.combo.scale)
        spr.position:set((spr:getWidth() * 0.5) + (((i - (combo < 0 and 2 or 1)) * 43) - 90), 60)
        
        spr.scale:set(self._skinData.combo.scale * 0.95, self._skinData.combo.scale * 0.95)
        if miss then
            spr:setTint(0xFFc84040)
        else
            spr:setTint(Color.WHITE)
        end
        spr.alpha = 1
        self:moveChild(spr, self:getChildCount())

        local t = Tween:new() --- @type comet.gfx.Tween
        t:target({target = spr.scale, properties = {x = self._skinData.combo.scale, y = self._skinData.combo.scale}})
        t:start({duration = 0.2})

        local t = Tween:new() --- @type comet.gfx.Tween
        t.onComplete:connect(function()
            spr:kill()
        end)
        t:target({target = spr, properties = {alpha = 0}})
        t:start({duration = 0.2, delay = Conductor.instance:getCurrentBeatLength() * 0.002})
    end
end

function ScoreDisplay:_draw()
    Image.NO_OFF_SCREEN_CHECKS, AnimatedImage.NO_OFF_SCREEN_CHECKS = true, true
    super._draw(self)
    Image.NO_OFF_SCREEN_CHECKS, AnimatedImage.NO_OFF_SCREEN_CHECKS = false, false
end

return ScoreDisplay