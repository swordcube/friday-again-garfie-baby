local fs = love.filesystem

local Script = srcreq("funkin.scripting.script") --- @type funkin.scripting.Script
local ScriptPack = srcreq("funkin.scripting.scriptpack") --- @type funkin.scripting.ScriptPack

--- @class funkin.screens.MusicBeatSubScreen : comet.core.Screen
local MusicBeatSubScreen, super = Screen:subclass("MusicBeatSubScreen", ...)

function MusicBeatSubScreen:__init__(scriptName)
    super.__init__(self)
    self.scriptName = scriptName

    --- Shortcut to global controls instance
    self.controls = Controls.static.instance --- @type funkin.backend.Controls

    self.subScreenScripts = ScriptPack:new() --- @type funkin.scripting.ScriptPack
    self.subScreenScripts:linkObject(self)

    for loader in range(table.unpack(Paths._registeredAssetLoaders)) do
        local scriptPath = Paths.script(("subscreens/%s"):format(self.class.name), loader.id, false)
        if fs.isFile(scriptPath) then
            self.subScreenScripts:add(Script:new(scriptPath))
        end
        scriptPath = Paths.script(("substates/%s"):format(self.class.name), loader.id, false)
        if fs.isFile(scriptPath) then
            self.screenScripts:add(Script:new(scriptPath))
        end
    end
    self.subScreenScripts:call("new")
end

function MusicBeatSubScreen:enter()
    self.subScreenScripts:call("onEnter")
    self.subScreenScripts:call("onCreate")
end

function MusicBeatSubScreen:postEnter()
    self.subScreenScripts:call("onEnterPost")
    self.subScreenScripts:call("onCreatePost")
end

function MusicBeatSubScreen:exit()
    if self.subScreenScripts then
        self.subScreenScripts:call("onExit")
        self.subScreenScripts:call("onDestroy")
        
        self.subScreenScripts:close()
        self.subScreenScripts = nil
    end
end

function MusicBeatSubScreen:_update(dt)
    self.subScreenScripts:call("onUpdate", dt)
    super._update(self, dt)
    self.subScreenScripts:call("onUpdatePost", dt)
end

function MusicBeatSubScreen:stepHit(step)
    self.subScreenScripts:call("onStepHit", step)
end

function MusicBeatSubScreen:beatHit(beat)
    self.subScreenScripts:call("onBeatHit", beat)
end

function MusicBeatSubScreen:measureHit(measure)
    self.subScreenScripts:call("onMeasureHit", measure)
end

return MusicBeatSubScreen