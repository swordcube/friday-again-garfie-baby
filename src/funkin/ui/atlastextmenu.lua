--- @class funkin.ui.AtlasTextMenu : comet.gfx.Object2D
local AtlasTextMenu, super = Object2D:extend("AtlasTextMenu", ...)

function AtlasTextMenu:__init__(x, y)
    super.__init__(self, x, y)

    self.curSelected = 1

    self.enabled = true
end

function AtlasTextMenu:clearItems()
    for i = 1, self:getChildCount() do
        local item = self:getChild(i) --- @type funkin.ui.AtlasText
        item:destroy()
    end
    self.children = {}
    self._childCount = 0
    
    self.curSelected = 1
end

function AtlasTextMenu:addItem(text, font, onAccept, onSelect)
    local item = AtlasText:new(0, 0, font or "bold", 1, text) --- @type funkin.ui.AtlasText
    item.onAccept = onAccept
    item.onSelect = onSelect
    item.targetY = self:getChildCount()
    item.position:set(30, 70 * self:getChildCount())
    self:addChild(item)
    return item
end

function AtlasTextMenu:update(dt)
    local centerY = comet.getDesiredHeight() * 0.4
    for i = 1, self:getChildCount() do
        local item = self:getChild(i) --- @type funkin.ui.AtlasText
        local offset = i - self.curSelected

        local targetY = (offset * 156) + centerY
        item.position:lerp((offset * 20) + 90, targetY, dt * 9.6)

        local t = math.min(math.abs(item.position.y - centerY) / 156, 1)
        item:setAlpha(1 - (0.5 * t)) -- 1 near center, 0.5 at farthest
        item.visible = item.position.y < (centerY + 780) and item.position.y > (centerY - 780)
    end
end

function AtlasTextMenu:_draw()
    -- Prevent offscreen checks since we do it ourselves
    -- Too many sprites on-screen can get really laggy if they're
    -- all checking if they're off-screen
    AnimatedImage.NO_OFF_SCREEN_CHECKS = true
    super._draw(self)

    -- Then re-enable offscreen checks for other objects
    AnimatedImage.NO_OFF_SCREEN_CHECKS = false
end

function AtlasTextMenu:input(e)
    if e.type == "text" then
        return
    end
    if self.enabled then
        local wheel = comet.mouse.wheel.y
        if Controls.instance.justPressed.UI_UP or wheel < 0 then
            self:changeSelection(-1)
        end
        if Controls.instance.justPressed.UI_DOWN or wheel > 0 then
            self:changeSelection(1)
        end
        if Controls.instance.justPressed.ACCEPT then
            local item = self:getChild(self.curSelected) --- @type funkin.ui.AtlasText
            if item.onAccept then
                item.onAccept()
            end
        end
    end
end

function AtlasTextMenu:changeSelection(by, force)
    if by == 0 and not force then
        return
    end
    self.curSelected = math.wrap(self.curSelected + by, 1, self:getChildCount())
    comet.mixer:play(Paths.sound("menus/sfx/scroll"))

    local item = self:getChild(self.curSelected) --- @type funkin.ui.AtlasText
    if item.onSelect then
        item.onSelect()
    end
end

return AtlasTextMenu