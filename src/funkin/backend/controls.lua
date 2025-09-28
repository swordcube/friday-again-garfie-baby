local baton = require("thirdparty.baton")

--- @class funkin.backend.Controls : comet.util.Class
local Controls = Class("Controls", ...)

Controls.static.instance = nil --- @type funkin.backend.Controls

function Controls:__init__()
    self._input = baton.new({
        controls = {
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
            RESET = {"key:r"}
        }
    })
    self.justPressed = setmetatable({}, {
        __index = function(_, k)
            return self._input:pressed(k)
        end
    })
    self.pressed = setmetatable({}, {
        __index = function(_, k)
            return self._input:down(k)
        end
    })
    self.justPeleased = setmetatable({}, {
        __index = function(_, k)
            return self._input:released(k)
        end
    })
    self.released = setmetatable({}, {
        __index = function(_, k)
            return self._input:down(k)
        end
    })
    comet.signals.preUpdate:connect(function()
        self._input:update()
    end)
end

return Controls