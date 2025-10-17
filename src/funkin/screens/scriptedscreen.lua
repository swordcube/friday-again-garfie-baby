--- @class funkin.screens.ScriptedScreen : funkin.screens.MusicBeatScreen
local ScriptedScreen, super = MusicBeatScreen:subclass("ScriptedScreen", ...)

function ScriptedScreen:__init__(scriptName)
    self.scriptName = scriptName
    super.__init__(self)
end

return ScriptedScreen