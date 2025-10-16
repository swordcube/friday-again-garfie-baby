local fs = love.filesystem
local ScriptPack = srcreq("funkin.scripting.scriptpack") --- @type funkin.scripting.ScriptPack

--- @class funkin.scripting.GlobalScript
local GlobalScript = {}
GlobalScript.scripts = nil --- @type funkin.scripting.ScriptPack

function GlobalScript.init()
    local scripts = ScriptPack:new() --- @type funkin.scripting.ScriptPack
    GlobalScript.scripts = scripts

    comet.signals.preUpdate:connect(function()
        local dt = comet.settings.parallelUpdate and comet.getFullDeltaTime() or comet.getDeltaTime()
        scripts:call("onUpdate", dt)
    end)
    comet.signals.postUpdate:connect(function()
        local dt = comet.settings.parallelUpdate and comet.getFullDeltaTime() or comet.getDeltaTime()
        scripts:call("onUpdatePost", dt)
    end)
    comet.signals.preDraw:connect(function()
        scripts:call("onDraw")
    end)
    comet.signals.postDraw:connect(function()
        scripts:call("onDrawPost")
    end)
    comet.signals.preScreenSwitch:connect(function(pending)
        scripts:call("onScreenSwitch", pending)
        scripts:call("onStateSwitch", pending)
    end)
    comet.signals.postScreenSwitch:connect(function()
        scripts:call("onScreenSwitchPost")
        scripts:call("onStateSwitchPost")
    end)
    comet.signals.preInput:connect(function(e)
        scripts:call("onInput", e)
    end)
    comet.signals.postInput:connect(function(e)
        scripts:call("onInputPost", e)
    end)
end

function GlobalScript.reloadScripts()
    local scripts = GlobalScript.scripts
    scripts:close()
    scripts.scripts = {}

    for loader in range(table.unpack(Paths._registeredAssetLoaders)) do
        local scriptPath = Paths.script("global", loader.id, false)
        if fs.isFile(scriptPath) then
            scripts:add(Script:new(scriptPath))
        end
    end
    scripts:call("new")
end

return GlobalScript