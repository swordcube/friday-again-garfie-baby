--- @class funkin.scripting.events.ScriptEvent : comet.util.Class
local ScriptEvent = Class("ScriptEvent", ...)

ScriptEvent.static._cache = {} --- @protected

function ScriptEvent.get(type)
    if not ScriptEvent.static._cache[type] then
        local e = srcreq(("funkin.scripting.events.%s%s"):format(type, "event")):new() --- @type funkin.scripting.events.ScriptEvent
        ScriptEvent.static._cache[type] = e
    end
    return ScriptEvent.static._cache[type]
end

function ScriptEvent:__init__()
    self.cancelled = false

    self._defaultVars = {} --- @protected
end

function ScriptEvent:setupVar(var, val)
    self._defaultVars[var] = val
    return val
end

--- @return self
function ScriptEvent:recycle(vars)
    for key, value in pairs(vars) do
        if value ~= nil then
            self[key] = value
        else
            self[key] = self._defaultVars[key]
        end
    end
    self.cancelled = false
    return self
end

function ScriptEvent:cancel()
    self.cancelled = true
end

return ScriptEvent