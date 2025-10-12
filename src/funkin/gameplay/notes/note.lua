local json = cometreq("lib.json") --- @type comet.lib.Json
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Note : comet.gfx.AnimatedImage
local Note, super = AnimatedImage:subclass("Note", ...)

local dirs = {"left", "down", "up", "right"}

function Note:__init__()
    super.__init__(self)

    self.time = 0.0
    self.lane = 0
    self.length = 0.0
    self.type = "default"

    self.skin = "funkin"
    self.skinData = nil

    self.wasHit = false
    self.strumLine = nil --- @type funkin.gameplay.notes.StrumLine
    self.playField = nil --- @type funkin.gameplay.PlayField

    self.offsetX, self.offsetY = 0.0, 0.0
end

function Note:loadSkin(skin)
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.note.atlas.path)))
    for name, d in pairs(self.skinData.note.animation) do
        for i = 1, #dirs do
            local dir = dirs[i]
            local animData = d[dir]
    
            if animData.indices and animData.indices ~= json.null and #animData.indices > 0 then
                self:addAnimationByIndices(dir .. name, animData.prefix, animData.indices, animData.fps, animData.looped)
            else
                self:addAnimationByName(dir .. name, animData.prefix, animData.fps, animData.looped)
            end
            self:setAnimationOffset(dir .. name, (animData and animData.offset) and animData.offset[1] or 0.0, (animData and animData.offset) and animData.offset[2] or 0.0)
        end
    end
    self.alpha = self.skinData.note.alpha or 1.0
    self.scale:set(self.skinData.note.scale, self.skinData.note.scale)
    self.antialiasing = self.skinData.note.antialiasing ~= nil and self.skinData.note.antialiasing or true
end

--- @param time number
--- @param lane number
--- @param length number
--- @param type string
--- @param strumLine funkin.gameplay.notes.StrumLine
function Note:setup(time, lane, length, type, strumLine)
    self.time = time
    self.lane = lane
    self.length = length
    self.type = type
    self.strumLine = strumLine
    self.wasHit = false

    local strum = strumLine:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
    self:loadSkin(strum.skin)

    self:playAnimation(dirs[lane + 1] .. "scroll", true)
end

function Note:updatePosition()
    local strum = self.strumLine:getChild(self.lane + 1) --- @type funkin.gameplay.notes.Strum
    
    local baseX, baseY = self.strumLine.position.x + strum.position.x + self.offsetX, self.strumLine.position.y + strum.position.y + self.offsetY
    self.position.x = baseX

    local speed = self.strumLine.scrollSpeed
    if self.strumLine.downscroll then
        speed = -speed
    end
    self.position.y = baseY + (0.45 * (self.time - Conductor.instance:getCurrentPlayhead()) * speed)
end

function Note:update(dt)
    super.update(self, dt)
    self:updatePosition()

    if self.strumLine.botplay and self.time <= Conductor.instance:getCurrentPlayhead() then
        self.playField:hitNote(self)
    end
    if not self.strumLine.botplay and self.time <= Conductor.instance:getCurrentPlayhead() - (350 / self.strumLine.scrollSpeed) then
        self.playField:missNote(self)
    end
end

return Note