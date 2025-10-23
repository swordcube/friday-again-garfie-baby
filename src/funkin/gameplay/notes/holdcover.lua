local json = cometreq("lib.json") --- @type comet.lib.Json
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.HoldCover : comet.gfx.AnimatedImage
local HoldCover, super = AnimatedImage:subclass("HoldCover", ...)

local dirs = {"left", "down", "up", "right"}

function HoldCover:__init__()
    super.__init__(self)

    self.lane = 0
    self.note = nil --- @type funkin.gameplay.notes.Note

    self.skin = "funkin"
    self.skinData = nil

    self.strumLine = nil --- @type funkin.gameplay.notes.StrumLine
    self.playField = nil --- @type funkin.gameplay.PlayField

    self.offsetX, self.offsetY = 0.0, 0.0

    self.onComplete:connect(function(name)
        if name:endsWith("start") then
            self.animation:play(dirs[self.lane + 1] .. "hold", true)
        
        elseif name:endsWith("end") then
            self:kill()
        end
    end)
end

function HoldCover:loadSkin(skin)
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    if not self.skinData.holdCovers then
        self.skin = "funkin"
        self.skinData = NoteSkin.get("funkin")
    end
    -- TODO: more than just sparrow atlas!!

    self.animCount = 0
    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.holdCovers.atlas.path)))

    if self.playField then
        self.playField:cacheAtlas(("#_HOLDCOVER_%s"):format(self.skin), self:getFrameCollection())
    end
    for name, d in pairs(self.skinData.holdCovers.animation) do
        for i = 1, #dirs do
            local dir = dirs[i]
            local animData = d[dir]
    
            if animData.indices and animData.indices ~= json.null and #animData.indices > 0 then
                self.animation:addByIndices(dir .. name, animData.prefix, animData.indices, animData.fps, animData.looped)
            else
                self.animation:addByName(dir .. name, animData.prefix, animData.fps, animData.looped)
            end
            self:setAnimationOffset(dir .. name, (animData and animData.offset) and animData.offset[1] or 0.0, (animData and animData.offset) and animData.offset[2] or 0.0)
        end
    end
    if self.skinData.holdCovers.offset then
        self.offset:set(self.skinData.holdCovers.offset[1], self.skinData.holdCovers.offset[2])
    end
    self.alpha = self.skinData.holdCovers.alpha or 1.0
    self.scale:set(self.skinData.holdCovers.scale, self.skinData.holdCovers.scale)
    self.antialiasing = self.skinData.holdCovers.antialiasing ~= nil and self.skinData.holdCovers.antialiasing or true
end

--- @param lane number
--- @param note funkin.gameplay.notes.Note
--- @param skin string
--- @param strumLine funkin.gameplay.notes.StrumLine
function HoldCover:setup(lane, note, skin, strumLine)
    self.lane = lane
    self.note = note
    self.strumLine = strumLine

    self:loadSkin(skin or "funkin")
    self.animation:play(dirs[lane + 1] .. "start", true)
end

function HoldCover:updatePosition()
    local strum = self.strumLine:getChild(self.lane + 1) --- @type funkin.gameplay.notes.Strum
    
    local baseX, baseY = self.strumLine.position.x + strum.position.x + self.offsetX, self.strumLine.position.y + strum.position.y + self.offsetY
    self.position.x = baseX
    self.position.y = baseY
end

function HoldCover:update(dt)
    super.update(self, dt)
    self:updatePosition()

    if self.note.wasMissed then
        self:kill()
    end
    if self.note.wasHit and not self.note.wasMissed and not self.note.exists and not self:getCurrentAnimation():endsWith("end") then
        if self.note.strumLine.botplay then
            self:kill()
        else
            local strum = self.note.strumLine:getChild(self.lane + 1) --- @type funkin.gameplay.notes.Strum
            if strum:getCurrentAnimation():startsWith("confirm") then
                strum:playAnimation("press", true)
            end
            self.animation:play(dirs[self.lane + 1] .. "end", true)
        end
    end
end

return HoldCover