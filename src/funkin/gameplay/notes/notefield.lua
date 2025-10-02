local Note = srcreq("funkin.gameplay.notes.note") --- @type funkin.gameplay.notes.Note

--- @class funkin.gameplay.notes.NoteField : comet.gfx.Object2D
local NoteField, super = Object2D:subclass("NoteField", ...)

function NoteField:__init__()
    super.__init__(self)

    self.pendingNotes = {}
    self.curNoteIndex = 1

    self.playField = nil --- @type funkin.gameplay.PlayField
end

function NoteField:update(dt)
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    while self.curNoteIndex <= #self.pendingNotes do
        local noteData = self.pendingNotes[self.curNoteIndex]
        local strumLine = self.playField.strumLines:getChild(noteData.d < 4 and 2 or 1)
        if c:getCurrentRawTime() < noteData.t - 2500 then
            break
        end
        local note = Note:new() --- @type funkin.gameplay.notes.Note
        note:setup(noteData.t, noteData.d % strumLine.keyCount, noteData.l, noteData.k, strumLine)
        note:updatePosition()
        self:addChild(note)

        self.curNoteIndex = self.curNoteIndex + 1
    end
end

return NoteField