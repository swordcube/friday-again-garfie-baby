--- @class funkin.screens.ScriptedSubScreen : funkin.screens.MusicBeatSubScreen
local ScriptedSubScreen, super = MusicBeatSubScreen:extend("ScriptedSubScreen", ...)

function ScriptedSubScreen:__init__(scriptName)
    self.scriptName = scriptName
    super.__init__(self)
end

return ScriptedSubScreen