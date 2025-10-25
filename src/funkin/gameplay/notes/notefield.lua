local Note = srcreq("funkin.gameplay.notes.note") --- @type funkin.gameplay.notes.Note

--- @class funkin.gameplay.notes.NoteField : comet.gfx.Object2D
local NoteField, super = Object2D:extend("NoteField", ...)

local INTERVAL_30_FPS = 1.0 / 30.0

function NoteField:__init__()
    super.__init__(self)

    self.pendingNotes = {}
    self.curNoteIndex = 1

    self.playField = nil --- @type funkin.gameplay.PlayField

    self.sustains = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.sustains)

    self.notes = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.notes)

    self._createNote = function()
        local n = Note:new() --- @type funkin.gameplay.notes.Note
        self.sustains:addChild(n.sustain)
        return n
    end
    self._noteSpawnTimer = 0.0
end

function NoteField:update(dt)
    self._noteSpawnTimer = self._noteSpawnTimer + dt
    while self._noteSpawnTimer >= INTERVAL_30_FPS do
        local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
        while self.curNoteIndex <= #self.pendingNotes do
            local noteData = self.pendingNotes[self.curNoteIndex]
            local strumLine = self.playField.strumLines:getChild(noteData.d < 4 and 1 or 2)
            if c:getCurrentRawTime() < noteData.t - 1200 then
                break
            end
            local note = self.notes:recycle(Note, self._createNote) --- @type funkin.gameplay.notes.Note
            note.playField = self.playField

            note:setup(noteData.t, noteData.d % strumLine.keyCount, math.max(noteData.l or 0.0, 0.0), noteData.k or "Default", strumLine)
            note:updatePosition()

            note.sustain:setup(note)
            note.sustain:updateVisuals()

            self.curNoteIndex = self.curNoteIndex + 1
        end
        self._noteSpawnTimer = self._noteSpawnTimer - INTERVAL_30_FPS
    end
end

function NoteField:_draw()
    Image.NO_OFF_SCREEN_CHECKS, AnimatedImage.NO_OFF_SCREEN_CHECKS = true, true
    super._draw(self)
    Image.NO_OFF_SCREEN_CHECKS, AnimatedImage.NO_OFF_SCREEN_CHECKS = false, false
end

return NoteField