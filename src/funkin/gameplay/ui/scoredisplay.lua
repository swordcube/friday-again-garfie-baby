local UISkin = srcreq("funkin.gameplay.ui.uiskin") --- @type funkin.gameplay.ui.UISkin
local RuntimeTextureAtlas = srcreq("funkin.gfx.rta") --- @type funkin.gfx.RuntimeTextureAtlas
local AnimatedVelocityImage = srcreq("funkin.gfx.animatedvelocityimage") --- @type funkin.gfx.AnimatedVelocityImage

--- @class funkin.gameplay.ui.ScoreDisplay : comet.gfx.Object2D
local ScoreDisplay, super = Object2D:subclass("ScoreDisplay", ...)

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
    self._scoreAtlas = ta:toFrameCollection()
    self._scoreAtlas:reference()
end

function ScoreDisplay:showRating(rating)
    local spr = AnimatedVelocityImage:new() --- @type funkin.gfx.AnimatedVelocityImage
    spr:setFrameCollection(self._scoreAtlas)
    spr:addAnimationByName("r", rating, 0, false)
    spr:playAnimation("r", true)
    spr.position:set(40, -60)
    spr.acceleration.y = 550
    spr.velocity.x = math.floor(love.math.random(0, -10))
    spr.velocity.y = math.floor(love.math.random(-140, -175))
    spr.scale:set(self._skinData.rating.scale * 0.95, self._skinData.rating.scale * 0.95)
    self:addChild(spr)

    local t = Tween:new() --- @type comet.gfx.Tween
    t:target({target = spr.scale, properties = {x = self._skinData.rating.scale, y = self._skinData.rating.scale}})
    t:start({duration = 0.2})

    local t = Tween:new() --- @type comet.gfx.Tween
    t.onComplete:connect(function()
        spr:destroy()
    end)
    t:target({target = spr, properties = {alpha = 0}})
    t:start({duration = 0.2, delay = Conductor.instance:getCurrentBeatLength() * 0.001})
end

function ScoreDisplay:showCombo(combo)
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
        local spr = AnimatedVelocityImage:new() --- @type funkin.gfx.AnimatedVelocityImage
        spr:setFrameCollection(self._scoreAtlas)
        spr:addAnimationByName("c", char, 0, false)
        spr:playAnimation("c", true)
        spr.position:set(((i - (combo < 0 and 2 or 1)) * 43) - 100, 60)
        spr.acceleration.y = math.floor(love.math.random(200, 300))
        spr.velocity.x = love.math.random(-5, 5)
        spr.velocity.y = math.floor(love.math.random(-140, -160))
        spr.scale:set(self._skinData.combo.scale * 0.95, self._skinData.combo.scale * 0.95)
        self:addChild(spr)

        local t = Tween:new() --- @type comet.gfx.Tween
        t:target({target = spr.scale, properties = {x = self._skinData.combo.scale, y = self._skinData.combo.scale}})
        t:start({duration = 0.2})

        local t = Tween:new() --- @type comet.gfx.Tween
        t.onComplete:connect(function()
            spr:destroy()
        end)
        t:target({target = spr, properties = {alpha = 0}})
        t:start({duration = 0.2, delay = Conductor.instance:getCurrentBeatLength() * 0.002})
    end
end

return ScoreDisplay