local fs = love.filesystem
local Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition

local Script = srcreq("funkin.scripting.script") --- @type funkin.scripting.Script
local ScriptPack = srcreq("funkin.scripting.scriptpack") --- @type funkin.scripting.ScriptPack

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

    self.screenScripts = ScriptPack:new() --- @type funkin.scripting.ScriptPack
    self.screenScripts:linkObject(self)

    for loader in range(table.unpack(Paths._registeredAssetLoaders)) do
        local scriptPath = Paths.script(("screens/%s"):format(self.scriptName or self.class.name), loader.id, false)
        if fs.isFile(scriptPath) then
            self.screenScripts:add(Script:new(scriptPath))
        end
        scriptPath = Paths.script(("states/%s"):format(self.scriptName or self.class.name), loader.id, false)
        if fs.isFile(scriptPath) then
            self.screenScripts:add(Script:new(scriptPath))
        end
    end
    self.screenScripts:call("new")
end

function MusicBeatScreen:enter()
    self.screenScripts:call("onEnter")
    self.screenScripts:call("onCreate")
end

function MusicBeatScreen:postEnter()
    self.screenScripts:call("onEnterPost")
    self.screenScripts:call("onCreatePost")
end

function MusicBeatScreen:exit()
    if self.screenScripts then
        self.screenScripts:call("onExit")
        self.screenScripts:call("onDestroy")
        
        self.screenScripts:close()
        self.screenScripts = nil
    end
end

function MusicBeatScreen:startIntro()
    self.screenScripts:call("onStartIntro")
    
    if not MusicBeatScreen.static.skipNextTransIn then
        self.currentTransition = Transition.static.currentType:new("in") --- @type funkin.ui.Transition
        self:openSubScreen(self.currentTransition)
    end
    MusicBeatScreen.static.skipNextTransIn = false

    self.screenScripts:call("onStartIntroPost")
end

function MusicBeatScreen:_update(dt)
    self.screenScripts:call("onUpdate", dt)
    super._update(self, dt)
    self.screenScripts:call("onUpdatePost", dt)
end

function MusicBeatScreen:stepHit(step)
    self.screenScripts:call("onStepHit", step)
end

function MusicBeatScreen:beatHit(beat)
    self.screenScripts:call("onBeatHit", beat)
end

function MusicBeatScreen:measureHit(measure)
    self.screenScripts:call("onMeasureHit", measure)
end

function MusicBeatScreen:startOutro(onOutroComplete)
    self.screenScripts:call("onStartOutro")
    
    if not MusicBeatScreen.skipNextTransOut then
        self.currentTransition = Transition.static.currentType:new("out", onOutroComplete) --- @type funkin.ui.Transition
        self:openSubScreen(self.currentTransition)
    else
        onOutroComplete()
    end
    MusicBeatScreen.skipNextTransOut = false
    
    self.screenScripts:call("onStartOutroPost")
end

return MusicBeatScreen