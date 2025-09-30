local Strum = srcreq("funkin.gameplay.notes.strum") --- @type funkin.gameplay.notes.Strum

--- @class funkin.gameplay.notes.StrumLine : comet.gfx.Object2D
local StrumLine, super = Object2D:subclass("StrumLine", ...)

function StrumLine:__init__(x, y, keyCount, skin)
    super.__init__(self, x, y)

    self.keyCount = keyCount or 4
    self.skin = skin or "funkin"

    for i = 1, self.keyCount do
        local strum = Strum:new(((i - 1) - (self.keyCount * 0.5) + 0.5) * 112, 0, self.keyCount, i - 1, self.skin) --- @type funkin.gameplay.notes.Strum
        self:addChild(strum)
    end
end

return StrumLine