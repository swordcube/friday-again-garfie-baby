local json = cometreq("lib.json")                         --- @type comet.lib.Json

local Sustain = srcreq("funkin.gameplay.notes.sustain")   --- @type funkin.gameplay.notes.Sustain
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Note : comet.gfx.AnimatedImage
local Note, super = AnimatedImage:extend("Note", ...)

local dirs = { "left", "down", "up", "right" }
local upperDirs = { "LEFT", "DOWN", "UP", "RIGHT" }

function Note:__init__()
    super.__init__(self)

    self.time = 0.0
    self.lane = 0
    self.length = 0.0
    self.type = "Default"

    self.skin = "funkin"
    self.skinData = nil

    self.wasHit = false
    self.wasMissed = false

    self.strumLine = nil         --- @type funkin.gameplay.notes.StrumLine
    self.playField = nil         --- @type funkin.gameplay.PlayField

    self.sustain = Sustain:new() --- @type funkin.gameplay.notes.Sustain
    self.sustain.note = self

    self.offsetX, self.offsetY = 0.0, 0.0
end

function Note:loadSkin(skin)
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    if not self.skinData.note then
        self.skin = "funkin"
        self.skinData = NoteSkin.get("funkin")
    end
    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.note.atlas.path)))
    for name, d in pairs(self.skinData.note.animation) do
        for i = 1, #dirs do
            local dir = dirs[i]
            local animData = d[dir]

            if animData.indices and animData.indices ~= json.null and #animData.indices > 0 then
                self.animation:addByIndices(dir .. name, animData.prefix, animData.indices, animData.fps, animData.looped)
            else
                self.animation:addByName(dir .. name, animData.prefix, animData.fps, animData.looped)
            end
            self.animation:setOffset(dir .. name, (animData and animData.offset) and animData.offset[1] or 0.0,
                (animData and animData.offset) and animData.offset[2] or 0.0)
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
    self.wasMissed = false
    self.alpha, self.sustain.alpha, self.visible = 1, 1, true

    self.stepLength = Conductor.instance:getCurrentStepLength()
    self.holdTime = self.time
    self.holdScoreBonus = 145

    local strum = strumLine:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
    self:loadSkin(strum.skin)

    self.offsetX, self.offsetY = 0.0, 0.0
    self.animation:play(dirs[lane + 1] .. "scroll", true)
end

function Note:updatePosition()
    local strum = self.strumLine:getChild(self.lane + 1) --- @type funkin.gameplay.notes.Strum

    local baseX, baseY = self.strumLine.position.x + strum.position.x + self.offsetX,
        self.strumLine.position.y + strum.position.y + self.offsetY
    self.position.x = baseX

    local speed = self.strumLine.scrollSpeed
    if self.strumLine.downscroll then
        speed = -speed
    end
    self.position.y = baseY + (0.45 * (self.time - Conductor.instance:getCurrentPlayhead()) * speed)
end

function Note:update(dt)
    super.update(self, dt)
    if not self.sustain then
        return
    end
    self:updatePosition()

    while self.length > 0 and self.exists and self.wasHit and not self.wasMissed and self.strumLine == self.playField.playerStrumLine and self.holdTime <= Conductor.instance:getCurrentPlayhead() do
        self.playField.stats.score = self.playField.stats.score + self.holdScoreBonus
        self.playField.hud:updatePlayerStats(self.playField.stats)
        
        self.holdTime = self.holdTime + self.stepLength
    end
    if not self.wasHit and self.strumLine.botplay and self.time <= Conductor.instance:getCurrentPlayhead() then
        self.playField:hitNote(self)
    end
    if not self.wasHit and not self.wasMissed and not self.strumLine.botplay and self.time <= Conductor.instance:getCurrentPlayhead() - 150 then
        -- if note is too late to hit, miss
        self.playField:missNote(self)
    end
    if self.wasHit and not self.wasMissed and not self.strumLine.botplay and self.time > Conductor.instance:getCurrentPlayhead() - (self.length - 100) and Controls.instance.justReleased["NOTE_" .. upperDirs[self.lane + 1]] then
        -- if you let go too early, miss
        self.playField:missNote(self)
    end
    if self.wasHit and not self.wasMissed and self.time <= Conductor.instance:getCurrentPlayhead() - self.length then
        -- if note is held all the way through, destroy it cuz it isn't needed anymore
        self:kill()
    end
    if self.wasMissed and self.time <= Conductor.instance:getCurrentPlayhead() - ((350 / self.strumLine.scrollSpeed) + self.length) then
        -- if note was missed and it goes off screen, destroy it
        self:kill()
    end
end

function Note:destroy()
    if self.sustain then
        self.sustain:destroy()
        self.sustain = nil
    end
    super.destroy(self)
end

return Note
