local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Strum : comet.gfx.AnimatedImage
local Strum, super = AnimatedImage:subclass("Strum", ...)

local math = math
local dirs = {"left", "down", "up", "right"}

function Strum:__init__(x, y, keyCount, direction, skin)
    super.__init__(self, x, y)

    self.keyCount = keyCount or 4
    self.direction = direction or 0
    
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    self.holdTimer = 0.0

    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.strum.atlas.path)))
    for name, d in pairs(self.skinData.strum.animation) do
        local animData = d[dirs[self.direction + 1]]

        if animData.indices and #animData.indices > 0 then
            self:addAnimationByIndices(name, animData.prefix, animData.indices, animData.fps, animData.looped)
        else
            self:addAnimationByName(name, animData.prefix, animData.fps, animData.looped)
        end
        self:setAnimationOffset(name, (animData and animData.offset) and animData.offset[1] or 0.0, (animData and animData.offset) and animData.offset[2] or 0.0)
    end
    self.scale:set(self.skinData.strum.scale, self.skinData.strum.scale)
    self:playAnimation("static")

    self.antialiasing = self.skinData.strum.antialiasing ~= nil and self.skinData.strum.antialiasing or true
end

function Strum:update(dt)
    self.holdTimer = self.holdTimer - (dt * 1000.0)
    if self.holdTimer <= 0.0 then
        self:playAnimation("static")
        self.holdTimer = math.huge
    end
    super.update(self, dt)
end

function Strum:glow(bot)
    self.holdTimer = bot and math.max(Conductor.instance:getCurrentStepLength(), 150) or math.huge
    self:playAnimation("confirm", true)
end

return Strum