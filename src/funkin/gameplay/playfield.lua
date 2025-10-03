local StrumLine = srcreq("funkin.gameplay.notes.strumline") --- @type funkin.gameplay.notes.StrumLine
local NoteField = srcreq("funkin.gameplay.notes.notefield") --- @type funkin.gameplay.notes.NoteField

--- @class funkin.gameplay.PlayField : comet.gfx.Object2D
local PlayField, super = Object2D:subclass("PlayField", ...)

local upperDirs = {"LEFT", "DOWN", "UP", "RIGHT"}

function PlayField:__init__()
    super.__init__(self)

    self.currentChart = nil
    self.currentDifficulty = "unknown"

    self.strumLines = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.strumLines)

    local downscroll = true

    self.opponentStrumLine = StrumLine:new(comet.getDesiredWidth() * 0.25, downscroll and comet.getDesiredHeight() - 100 or 100, downscroll) --- @type funkin.gameplay.notes.StrumLine
    self.opponentStrumLine.botplay = true
    self.strumLines:addChild(self.opponentStrumLine)
    
    self.playerStrumLine = StrumLine:new(comet.getDesiredWidth() * 0.75, downscroll and comet.getDesiredHeight() - 100 or 100, downscroll) --- @type funkin.gameplay.notes.StrumLine
    self.playerStrumLine.botplay = true
    self.strumLines:addChild(self.playerStrumLine)

    self.notes = NoteField:new() --- @type funkin.gameplay.notes.NoteField
    self.notes.playField = self
    self:addChild(self.notes)
end

function PlayField:prepareChart(chart, difficulty)
    self.currentChart = chart
    for _, notes in pairs(self.currentChart.notes) do
        table.sort(notes, function(a, b)
            if a.t ~= b.t then
                return a.t < b.t
            end
            return a.d < b.d
        end)
    end
    self.notes.pendingNotes = chart.notes[difficulty]
    self.notes.curNoteIndex = 1

    for i = 1, self.strumLines:getChildCount() do
        self.strumLines:getChild(i).scrollSpeed = self.currentChart.scrollSpeed[difficulty] or 1.0
    end
end

function PlayField:input(e)
    local plr = self.playerStrumLine
    if plr.botplay or e.isRepeat or e.type == "text" then
        return
    end
    local lane = -1
    local controls = Controls.instance --- @type funkin.backend.Controls
    
    for i = 1, plr.keyCount do
        local mappings = controls:getMappings()["NOTE_" .. upperDirs[i]]
        for j = 1, #mappings do
            local m = mappings[j]
            if m.type == "key" and m.key == e.key then
                lane = i - 1
                break
            end
        end
    end
    if lane == -1 then
        return
    end
    if e.pressed then
        local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
        local validNotes = table.filter(self.notes.children, function(n)
            return n and not n.wasHit and math.abs(n.time - c:getCurrentTime()) <= 216 and n.strumLine == plr and n.lane == lane
        end)
        table.sort(validNotes, function(a, b)
            return a.time < b.time
        end)
        local note = validNotes[1] --- @type funkin.gameplay.notes.Note
        local strum = plr:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
        if note then
            note.wasHit = true
            note:destroy()
        end
        strum:playAnimation(note and "confirm" or "press", true)
    else
        local strum = plr:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
        strum:playAnimation("static", true)
    end
end

return PlayField