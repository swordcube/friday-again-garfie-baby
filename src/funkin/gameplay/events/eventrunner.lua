local Signal = cometreq("util.signal") --- @type comet.util.Signal
local EventBehavior = srcreq("funkin.gameplay.events.behaviors.eventbehavior") --- @type funkin.gameplay.events.behaviors.EventBehavior

--- @class funkin.gameplay.events.EventRunner : comet.core.Object
local EventRunner, super = Object:subclass("EventRunner", ...)

function EventRunner:__init__()
    super.__init__(self)
    self.visible = false

    self.events = {}
    self.curEventIndex = 1

    self.behaviors = {}
    self.onExecute = Signal:new():type("string", "number", "table", "void") --- @type comet.util.Signal
end

function EventRunner:update(_)
    local playhead = Conductor.instance:getCurrentRawPlayhead()
    while self.curEventIndex <= #self.events do
        local event = self.events[self.curEventIndex]
        if event.t > playhead then
            break
        end
        self.behaviors[event.k]:execute(event.t, event.p)
        self.onExecute:emit(event.k, event.t, event.p)
        
        self.curEventIndex = self.curEventIndex + 1
    end
end

--- @return funkin.gameplay.events.behaviors.EventBehavior
function EventRunner:createBehavior(eventType)
    return EventBehavior:new(eventType)
end

function EventRunner:setEvents(events)
    self.behaviors = {}
    self.events = events

    for i = 1, #events do
        local event = events[i]
        if not self.behaviors[event.k] then
            local behavior = self:createBehavior(event.k) --- @type funkin.gameplay.events.behaviors.EventBehavior
            self.behaviors[event.k] = behavior
        end
    end
end

function EventRunner:destroy()
    if self.behaviors then
        for _, behavior in pairs(self.behaviors) do
            behavior:destroy()
        end
        self.behaviors = nil
    end
    self.onExecute = nil
end

return EventRunner