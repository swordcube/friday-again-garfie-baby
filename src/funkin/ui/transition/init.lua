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
    self.finishCallback = finishCallback --- @type function
end

function Transition:enter()
    
end

function Transition:finish()
    if self.finishCallback then
        self.finishCallback()
    end
    if self.type == "in" then
        self:destroy()
    end
end

return Transition