local Transition = srcreq("funkin.ui.transition") --- @type funkin.ui.Transition

--- @class funkin.ui.Transition.GradientSwipe : funkin.ui.Transition
local GradientSwipe, super = Transition:subclass("GradientSwipe", ...)

function GradientSwipe:enter()
    local type = self.type
    
    self.container = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.container)

    self.blackRect = Rectangle:new() --- @type comet.gfx.Rectangle
    self.blackRect.size:set(comet.getDesiredWidth(), comet.getDesiredHeight())
    self.blackRect:setTint(Color.BLACK)
    self.blackRect.centered = false
    self.container:addChild(self.blackRect)

    self.gradient = Image:new() --- @type comet.gfx.Image
    self.gradient:loadTexture(Paths.image("ui/transition/gradient"))
    self.gradient.centered = false
    self.gradient.scale:set(
        comet.getDesiredWidth() / self.gradient:getOriginalWidth(),
        comet.getDesiredHeight() / self.gradient:getOriginalHeight()
    )
    self.container:addChild(self.gradient)
    
    local duration = 0.66
    if type == "in" then
        self.gradient.scale.y = -self.gradient.scale.y

        self.gradient.position.y = -self.gradient:getHeight()
        self.container.position.y = 0.0
        
        local t = Tween:new() --- @type comet.gfx.Tween
        t:target({target = self.container.position, properties = {y = self.blackRect:getHeight() + self.gradient:getHeight()}})
        t:start({duration = duration, ease = "outSine"})
        t.onComplete:connect(function()
            self:finish()
        end)
    else
        self.gradient.position.y = self.blackRect:getHeight()
        self.container.position.y = -(self.blackRect:getHeight() + self.gradient:getHeight())
        
        local t = Tween:new() --- @type comet.gfx.Tween
        t:target({target = self.container.position, properties = {y = 0}})
        t:start({duration = duration, ease = "outSine"})
        t.onComplete:connect(function()
            self:finish()
        end)
    end
end

return GradientSwipe