local Signal = cometreq("util.signal") --- @type comet.util.Signal

--- @class funkin.ui.Transition : comet.core.Object
local Transition, super = Object:subclass("Transition", ...)

Transition.static.defaultType = nil --- @type funkin.ui.Transition
Transition.static.currentType = Transition.defaultType

function Transition.setDefaultTransition(type, setCurrent)
    Transition.static.defaultType = type
    if setCurrent then
        Transition.static.currentType = type
    end
end

function Transition:__init__(type, finishCallback)
    super.__init__(self)

    self.type = type --- @type "in"|"out"
    self.onFinish = Signal:new() --- @type comet.util.Signal

    if finishCallback then
        self.onFinish:connect(finishCallback)
    end
end

function Transition:enter()
    
end

function Transition:input(e)
    if e.type == "key" and e.pressed and (e.key == "lshift" or e.key == "rshift") then
        self:finish()
    end
end

function Transition:finish()
    self.onFinish:emit()
    if self.type == "in" then
        self:destroy()
    end
end

return Transition