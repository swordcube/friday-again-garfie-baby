local ScriptEvent = srcreq("funkin.scripting.events.scriptevent") --- @type funkin.scripting.events.ScriptEvent
local Scoring = srcreq("funkin.gameplay.scoring") --- @type funkin.gameplay.Scoring

--- @class funkin.scripting.events.NoteHitEvent : funkin.scripting.events.ScriptEvent
local NoteHitEvent, super = ScriptEvent:subclass("NoteHitEvent", ...)

function NoteHitEvent:__init__()
    super.__init__(self)

    self.note = self:setupVar("note", nil) --- @type funkin.gameplay.notes.Note
    self.strumLine = self:setupVar("strumLine", nil) --- @type funkin.gameplay.notes.StrumLine
    self.playField = self:setupVar("playField", nil) --- @type funkin.gameplay.PlayField

    self.rating = self:setupVar("rating", "killer") --- @type string
    self.combo = self:setupVar("combo", 0) --- @type integer

    self.score = self:setupVar("score", 500) --- @type integer
    self.health = self:setupVar("health", 0.0115) --- @type number

    self.showRating = self:setupVar("showRating", true) --- @type boolean
    self.showCombo = self:setupVar("showCombo", true) --- @type boolean

    self.showSplash = self:setupVar("showSplash", true) --- @type boolean
    self.showHoldCover = self:setupVar("showHoldCover", true) --- @type boolean
    
    self.playSingAnim = self:setupVar("playSingAnim", true) --- @type boolean
end

return NoteHitEvent