local Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition

--- @class funkin.screens.MusicBeatScreen : comet.core.Screen
local MusicBeatScreen, super = Screen:subclass("MusicBeatScreen", ...)

MusicBeatScreen.static.skipNextTransOut = false
MusicBeatScreen.static.skipNextTransIn = false

function MusicBeatScreen:__init__()
    super.__init__(self)

    --- Shortcut to global controls instance
    self.controls = Controls.static.instance --- @type funkin.backend.Controls

    --- Whether or not to stop updating this screen when a transition occurs.
    self.persistentUpdate = false
end

function MusicBeatScreen:startIntro()
    if not MusicBeatScreen.static.skipNextTransIn then
        self.currentTransition = Transition.static.currentType:new("in") --- @type funkin.ui.Transition
        self:openSubScreen(self.currentTransition)
    end
    MusicBeatScreen.static.skipNextTransIn = false
end

function MusicBeatScreen:stepHit(step) end
function MusicBeatScreen:beatHit(beat) end
function MusicBeatScreen:measureHit(measure) end

function MusicBeatScreen:startOutro(onOutroComplete)
    if not MusicBeatScreen.skipNextTransOut then
        self.currentTransition = Transition.static.currentType:new("out", onOutroComplete) --- @type funkin.ui.Transition
        self:openSubScreen(self.currentTransition)
    else
        onOutroComplete()
    end
    MusicBeatScreen.skipNextTransOut = false
end

return MusicBeatScreen