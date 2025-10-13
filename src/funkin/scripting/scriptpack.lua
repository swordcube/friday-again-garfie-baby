--- @class funkin.scripting.ScriptPack : comet.util.Class
local ScriptPack = Class("ScriptPack", ...)

function ScriptPack:__init__()
    self.scripts = {} --- @type funkin.scripting.Script[]

    self.linkedObject = nil --- @type any
    self.additionalDefaultVars = {}
end

function ScriptPack:linkObject(obj)
    if not obj then
        FLog.warn("You can't link an invalid object to a ScriptPack!")
        return
    end
    self.linkedObject = obj
end

--- @param script funkin.scripting.Script
function ScriptPack:preAdd(script)
    for key, value in pairs(self.additionalDefaultVars) do
        script:set(key, value)
    end
    if not script.linkedObject then
        script:linkObject(self.linkedObject)
    end
end

--- @param script funkin.scripting.Script
function ScriptPack:add(script)
    self:preAdd(script)
    table.insert(self.scripts, script)
end

--- @param script funkin.scripting.Script
function ScriptPack:remove(script)
    table.removeItem(self.scripts, script)
end

function ScriptPack:call(func, ...)
    for i = 1, #self.scripts do
        local script = self.scripts[i] --- @type funkin.scripting.Script
        script:call(func, ...)
    end
end

function ScriptPack:close()
    if not self.scripts then
        return
    end
    for i = 1, #self.scripts do
        local script = self.scripts[i] --- @type funkin.scripting.Script
        script:close()
    end
    self.scripts = nil
end

return ScriptPack