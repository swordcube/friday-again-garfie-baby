local json = cometreq("lib.json") --- @type comet.lib.Json
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Strum : comet.gfx.AnimatedImage
local Strum, super = AnimatedImage:extend("Strum", ...)

local math = math
local dirs = {"left", "down", "up", "right"}

function Strum:__init__(x, y, keyCount, direction, skin)
    super.__init__(self, x, y)

    self.keyCount = keyCount or 4
    self.direction = direction or 0
    
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    if not self.skinData.strum then
        self.skin = "funkin"
        self.skinData = NoteSkin.get("funkin")
    end
    self.holdTimer = 0.0
    self.susLength = 0.0

    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.strum.atlas.path)))
    for name, d in pairs(self.skinData.strum.animation) do
        local animData = d[dirs[self.direction + 1]]

        if animData.indices and animData.indices ~= json.null and #animData.indices > 0 then
            self.animation:addByIndices(name, animData.prefix, animData.indices, animData.fps, animData.looped)
        else
            self.animation:addByName(name, animData.prefix, animData.fps, animData.looped)
        end
        self:setAnimationOffset(name, (animData and animData.offset) and animData.offset[1] or 0.0, (animData and animData.offset) and animData.offset[2] or 0.0)
    end
    self.scale:set(self.skinData.strum.scale, self.skinData.strum.scale)
    self.animation:play("static")

    self.initialWidth, self.initialHeight = self:getWidth(), self:getHeight()

    self.alpha = self.skinData.strum.alpha or 1.0
    self.antialiasing = self.skinData.strum.antialiasing ~= nil and self.skinData.strum.antialiasing or true

    self.onComplete:connect(function(name)
        if name == "confirm" and self.susLength > 0.0 then
            if self:hasAnimation("confirm-hold") then
                self.animation:play("confirm-hold", true)
            end
        end
    end)
end

function Strum:update(dt)
    self.holdTimer = self.holdTimer - (dt * 1000.0)
    if self.holdTimer <= 0.0 then
        self.animation:play("static")
        self.holdTimer = math.huge
    end
    super.update(self, dt)
end

function Strum:glow(bot, susLength)
    self.susLength = susLength
    self.holdTimer = bot and math.max(susLength, 150) or math.huge
    self.animation:play("confirm", true)
end

return Strum