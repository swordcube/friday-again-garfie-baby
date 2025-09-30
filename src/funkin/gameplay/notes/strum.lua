local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Strum : comet.gfx.AnimatedImage
local Strum, super = AnimatedImage:subclass("Strum", ...)

local dirs = {"left", "down", "up", "right"}

function Strum:__init__(x, y, keyCount, direction, skin)
    super.__init__(self, x, y)

    self.keyCount = keyCount or 4
    self.direction = direction or 0
    
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.strum.atlas.path)))
    for name, d in pairs(self.skinData.strum.animation) do
        local animData = d[dirs[self.direction + 1]]

        if animData.indices and #animData.indices > 0 then
            self:addAnimationByIndices(name, animData.prefix, animData.indices, animData.fps, animData.looped)
        else
            self:addAnimation(name, animData.prefix, animData.fps, animData.looped)
        end
    end
    self.scale:set(self.skinData.strum.scale, self.skinData.strum.scale)
    self:playAnimation("static")

    self.antialiasing = self.skinData.strum.antialiasing ~= nil and self.skinData.strum.antialiasing or true
end

return Strum