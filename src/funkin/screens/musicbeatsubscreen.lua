--- @class funkin.screens.MusicBeatSubScreen : comet.core.Screen
local MusicBeatSubScreen, super = Screen:subclass("MusicBeatSubScreen", ...)

function MusicBeatSubScreen:__init__()
    super.__init__(self)

    --- Shortcut to global controls instance
    self.controls = Controls.static.instance --- @type funkin.backend.Controls
end

function MusicBeatSubScreen:stepHit(step) end
function MusicBeatSubScreen:beatHit(beat) end
function MusicBeatSubScreen:measureHit(measure) end

return MusicBeatSubScreen