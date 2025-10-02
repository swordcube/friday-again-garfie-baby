--- @class funkin.backend.Controls : comet.util.Class
local Controls = Class("Controls", ...)

Controls.static.instance = nil --- @type funkin.backend.Controls

function Controls:__init__()
    self._rawMappings = {}

    self._mappings = {}
    self._mappingNames = {}
    
    self:setMappings({
        NOTE_LEFT = {"key:a", "key:left"},
        NOTE_DOWN = {"key:s", "key:down"},
        NOTE_UP = {"key:w", "key:up"},
        NOTE_RIGHT = {"key:d", "key:right"},

        UI_LEFT = {"key:a", "key:left"},
        UI_DOWN = {"key:s", "key:down"},
        UI_UP = {"key:w", "key:up"},
        UI_RIGHT = {"key:d", "key:right"},

        ACCEPT = {"key:return", "key:space"},
        BACK = {"key:backspace", "key:escape"},
        RESET = {"key:r", nil},

        OVERLAY = {"key:f3", nil},
        RELOAD = {"key:f5", nil},
        EMERGENCY = {"key:f7", nil}
    })

    self.justPressed = {}
    self.pressed = {}
    self.justReleased = {}
    self.released = {}

    comet.signals.preInput:connect(function(e)
        self:onInput(e)
    end)
    comet.signals.postUpdate:connect(function()
        self:update()
    end)
end

function Controls:updateBindNames()
    self._mappingNames = {}
    for key, _ in pairs(self._mappings) do
        self._mappingNames[#self._mappingNames + 1] = key
    end
end

function Controls:getMappings()
    return self._mappings
end

function Controls:getRawMappings()
    return self._rawMappings
end

function Controls:setMappings(newMappings)
    self._mappings = {}
    self._rawMappings = newMappings

    for key, binds in pairs(newMappings) do
        local set = {}
        for i = 1, #binds do
            local rawBind = binds[i] --- @type string
            if not rawBind then
                goto continue
            end
            if rawBind:startsWith("key:") then
                local bind = {type = "key", key = rawBind:sub(5)}
                set[#set + 1] = bind
            elseif rawBind:startsWith("mouse:") then
                local bind = {type = "mouse", button = tonumber(rawBind:sub(7))}
                set[#set + 1] = bind
            end
            ::continue::
        end
        self._mappings[key] = set
    end
    self:updateBindNames()
end

function Controls:onInput(e)
    if e.type == "key" and not e.isRepeat then
        for i = 1, #self._mappingNames do
            local name = self._mappingNames[i]
            local binds = self._mappings[name]
            for j = 1, #binds do
                if binds[j].key == e.key then
                    if e.pressed and not self.pressed[name] then
                        self.justPressed[name] = true
                        self.pressed[name] = true
                    
                    elseif not e.pressed and self.pressed[name] then
                        self.justReleased[name] = true
                        self.pressed[name] = false
                    end
                    break
                end
            end
        end
    elseif e.type == "mousebutton" then
        for i = 1, #self._mappingNames do
            local name = self._mappingNames[i]
            local binds = self._mappings[name]
            for j = 1, #binds do
                if binds[j].button == e.button then
                    if e.pressed and not self.pressed[name] then
                        self.justPressed[name] = true
                        self.pressed[name] = true
                    
                    elseif not e.pressed and self.pressed[name] then
                        self.justReleased[name] = true
                        self.pressed[name] = false
                    end
                    break
                end
            end
        end
    end
end

function Controls:update()
    for i = 1, #self._mappingNames do
        local name = self._mappingNames[i]
        self.justPressed[name] = false
        self.justReleased[name] = false
    end
end

return Controls