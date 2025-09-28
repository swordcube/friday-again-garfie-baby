local Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition

--- @class funkin.screens.MusicBeatScreen : comet.core.Screen
local MusicBeatScreen, super = Screen:subclass("MusicBeatScreen", ...)

MusicBeatScreen.static.skipNextTransOut = false
MusicBeatScreen.static.skipNextTransIn = false

function MusicBeatScreen:__init__()
    super.__init__(self)

    --- Whether or not to stop updating this screen when a transition occurs.
    self.persistentUpdate = false
    
    --- Whether or not a transition is currently occuring.
    self.showingTransition = false

    --- The currently active transition.
    self.currentTransition = nil --- @type funkin.ui.Transition
end

function MusicBeatScreen:startIntro()
    if not MusicBeatScreen.static.skipNextTransIn then
        if not self.persistentUpdate then
            self.updateMode = "never"
        end
        if self.showingTransition and self.currentTransition then
            self.currentTransition:destroy()
            self.currentTransition = nil
        end
        self.showingTransition = true

        self.currentTransition = Transition.static.currentType:new("in") --- @type funkin.ui.Transition
        self.currentTransition.updateMode = "always"
        self.currentTransition:enter()
        self:addChild(self.currentTransition)
    end
    MusicBeatScreen.static.skipNextTransIn = false
end

function MusicBeatScreen:stepHit(step) end
function MusicBeatScreen:beatHit(beat) end
function MusicBeatScreen:measureHit(measure) end

function MusicBeatScreen:startOutro(onOutroComplete)
    if not MusicBeatScreen.skipNextTransOut then
        if not self.persistentUpdate then
            self.updateMode = "never"
        end
        if self.showingTransition and self.currentTransition then
            self.currentTransition:destroy()
            self.currentTransition = nil
        end
        self.showingTransition = true

        self.currentTransition = Transition.static.currentType:new("out", onOutroComplete) --- @type funkin.ui.Transition
        self.currentTransition.updateMode = "always"
        self.currentTransition:enter()
        self:addChild(self.currentTransition)
    else
        onOutroComplete()
    end
    MusicBeatScreen.skipNextTransOut = false
end

return MusicBeatScreen