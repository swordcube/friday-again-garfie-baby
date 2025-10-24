local ScriptEvent = srcreq("funkin.scripting.events.scriptevent") --- @type funkin.scripting.events.ScriptEvent

--- @class funkin.scripting.events.NoteMissEvent : funkin.scripting.events.ScriptEvent
local NoteMissEvent, super = ScriptEvent:extend("NoteMissEvent", ...)

function NoteMissEvent:__init__()
    super.__init__(self)

    self.note = self:setupVar("note", nil) --- @type funkin.gameplay.notes.Note
    self.strumLine = self:setupVar("strumLine", nil) --- @type funkin.gameplay.notes.StrumLine
    self.playField = self:setupVar("playField", nil) --- @type funkin.gameplay.PlayField

    self.combo = self:setupVar("combo", 0) --- @type integer
    
    self.score = self:setupVar("score", 100) --- @type integer
    self.health = self:setupVar("health", 0.02375) --- @type number

    self.showRating = self:setupVar("showRating", true) --- @type boolean
    self.showCombo = self:setupVar("showCombo", true) --- @type boolean

    self.playMissAnim = self:setupVar("playMissAnim", true) --- @type boolean
end

return NoteMissEvent