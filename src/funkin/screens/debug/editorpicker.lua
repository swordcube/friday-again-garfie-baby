--- @class funkin.screens.debug.EditorPicker : funkin.screens.MusicBeatSubScreen
local EditorPicker = MusicBeatSubScreen:subclass("EditorPicker", ...)

function EditorPicker:enter()
    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg_desat"))
    self.bg:screenCenter("xy")
    self.bg:setTint(0xFF4CAF50)
    self:addChild(self.bg)

    self.camFollow = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.camFollow)

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.TRANSPARENT)
    self.camera:follow(self.camFollow, "lockon", 0.16)
    self:addChild(self.camera)

    self.items = {
        {
            name = "Chart Editor",
            callback = function()
                print("not yet!! sorry!!")
            end
        },
        {
            name = "Chart Converter",
            callback = function()
                self:switchTo(srcreq("funkin.screens.debug.chartconverter"):new())
            end
        },
        {
            name = "Character Editor",
            callback = function()
                self:switchTo(srcreq("funkin.screens.debug.charactereditor"):new())
            end
        },
        {
            name = "UI Debug Screen",
            callback = function()
                self:switchTo(srcreq("funkin.screens.debug.uidebugscreen"):new())
            end
        }
    }
    self.uiLayer = Parallax2D:new() --- @type comet.gfx.Parallax2D
    self.uiLayer.scrollFactor.x = 0.0
    self.camera:addChild(self.uiLayer)

    self.grpItems = Object2D:new() --- @type comet.gfx.Object2D
    self.uiLayer:addChild(self.grpItems)

    self.curSelected = 1

    for i = 1, #self.items do
        local item = self.items[i]
        local text = AtlasText:new(0, 0, "bold", 1, item.name) --- @type funkin.ui.AtlasText
        text.position:set(0, 90 * (i - 1))
        text:setAlignment("center")
        text:screenCenter("x")
        self.grpItems:addChild(text)
    end
    self.camFollow.position:set(self.grpItems:getChild(1).position.x, self.grpItems:getChild(1).position.y + 100)
    self:changeSelection(0, true)
end

function EditorPicker:changeSelection(by, force)
    if by == 0 and not force then
        return
    end
    self.curSelected = math.wrap(self.curSelected + by, 1, #self.items)

    for i = 1, self.grpItems:getChildCount() do
        local text = self.grpItems:getChild(i) --- @type funkin.ui.AtlasText
        text:setAlpha(i == self.curSelected and 1.0 or 0.5)
    end
    self.camFollow.position:set(self.grpItems:getChild(self.curSelected).position.x, self.grpItems:getChild(self.curSelected).position.y + 100)
    comet.mixer:play(Paths.sound("menus/sfx/scroll"))
end

function EditorPicker:input(_)
    local wheel = comet.mouse.wheel.y
    if self.controls.justPressed.UI_UP or wheel < 0 then
        self:changeSelection(-1)
    end
    if self.controls.justPressed.UI_DOWN or wheel > 0 then
        self:changeSelection(1)
    end
    if self.controls.justPressed.BACK then
        self:close()
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
    end
    if self.controls.justPressed.ACCEPT then
        local item = self.items[self.curSelected]
        if item.callback then
            item.callback()
        end
    end
end

return EditorPicker