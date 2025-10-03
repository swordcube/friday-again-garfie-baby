--- @class funkin.screens.debug.ChartConverter : funkin.screens.MusicBeatScreen
local ChartConverter = MusicBeatScreen:subclass("ChartConverter", ...)

function ChartConverter:enter()
    self.persistentUpdate = true

    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg_transparent"))
    self.bg:screenCenter("xy")
    self.bg.alpha = 0.1
    self:addChild(self.bg)

    self.chartFormatIconAtlas = FrameCollection.fromTexture(Paths.image("menus/chart_formats"), 64, 64)
    self.chartFormatIconAtlas:reference()

    self.selectorBox = Rectangle:new(0, 105) --- @type comet.gfx.Rectangle
    self.selectorBox.size:set(comet.getDesiredWidth(), 60)
    self.selectorBox.centered = false
    self.selectorBox:screenCenter("x")
    self.selectorBox:setTint(Color.WHITE)
    self.selectorBox.alpha = 0.1
    self:addChild(self.selectorBox)

    self.grpIcons = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.grpIcons)

    self.grpTexts = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.grpTexts)

    self.noteText = Label:new() --- @type comet.gfx.Label
    self.noteText.centered = false
    self.noteText.borderSize = 2
    self.noteText:setFont(Paths.font("fonts/vcr"))
    self.noteText:setSize(20)
    self.noteText:setBorderColor(Color.BLACK)
    self.noteText:setColor(Color.WHITE)
    self.noteText.text = "Select a format to convert from!"
    self.noteText.position:set(comet.getDesiredWidth() - self.noteText:getWidth() - 15, comet.getDesiredHeight() - self.noteText:getHeight() - 12)
    self:addChild(self.noteText)

    self.formats = {
        {id = "fnf_legacy", name = "FNF Legacy", icon = 1},
        {id = "fnf_vslice", name = "FNF V-Slice", icon = 1},
        {id = "fnf_psych", name = "Psych Engine (0.x)", icon = 1},
        {id = "fnf_psych_1x", name = "Psych Engine (1.x)", icon = 1},
        {id = "fnf_codename", name = "Codename Engine", icon = 1},
        {id = "guitar_hero", name = "Guitar Hero", icon = 2},
        {id = "osu_mania", name = "osu!mania", icon = 3},
        {id = "quaver", name = "Quaver", icon = 4},
        {id = "stepmania", name = "StepMania", icon = 5},
    }
    self.curSelected = 1
    self.canInput = false

    self:regenItems()
end

function ChartConverter:update(dt)
    if self.controls.justPressed.BACK then
        self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
    end
    self.selectorBox.position.y = math.lerp(self.selectorBox.position.y, self.grpIcons:getChild(self.curSelected).position.y - 5, dt * 25)
    self.selectorBox.scale.y = 1 + math.abs((self.selectorBox.position.y - (self.grpIcons:getChild(self.curSelected).position.y - 5)) / 60)
end

function ChartConverter:input(_)
    local wheel = comet.mouse.wheel.y
    if self.controls.justPressed.UI_UP or wheel < 0 then
        self:changeSelection(-1)
    end
    if self.controls.justPressed.UI_DOWN or wheel > 0 then
        self:changeSelection(1)
    end
end

function ChartConverter:changeSelection(by, force)
    if by == 0 and not force then
        return
    end
    self.curSelected = math.wrap(self.curSelected + by, 1, #self.formats)

    for i = 1, self.grpIcons:getChildCount() do
        local icon = self.grpIcons:getChild(i) --- @type comet.gfx.AnimatedImage
        icon.alpha = i == self.curSelected and 1 or 0.5

        local text = self.grpTexts:getChild(i) --- @type funkin.ui.AtlasText
        text.alpha = i == self.curSelected and 1 or 0.5
    end
    comet.mixer:play(Paths.sound("menus/sfx/scroll"))
end

function ChartConverter:regenItems()
    self.canInput = false
    Timer.wait(#self.formats / 9, function()
        self.canInput = true
    end)
    for i = 1, #self.formats do
        local format = self.formats[i]

        local icon = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
        icon:setFrameCollection(self.chartFormatIconAtlas)
        icon:addAnimation("idle", {format.icon}, 0, false)
        icon:playAnimation("idle")
        icon:setGraphicSize(50, 50)
        icon.position:set(90, (60 * (i - 1)) + 70)
        icon.centered = false
        icon.alpha = 0
        self.grpIcons:addChild(icon)

        local text = AtlasText:new(0, 0, "bold", 0.78, format.name) --- @type funkin.ui.AtlasText
        text.position:set(170, (60 * (i - 1)) + 10)
        text:setAlpha(0.0)
        self.grpTexts:addChild(text)

        local t = Tween:new() --- @type comet.gfx.Tween
        t:target({target = icon, properties = {alpha = i == self.curSelected and 1 or 0.5}})
        t:target({target = icon.position, properties = {y = icon.position.y + 10}})
        
        t:target({target = text, properties = {alpha = i == self.curSelected and 1 or 0.5}})
        t:target({target = text.position, properties = {y = text.position.y + 10}})
        
        t:start({duration = 0.75, delay = 0.1 + (0.07 * (i - 1)), ease = "outCubic"})
    end
end

function ChartConverter:exit()
    self.chartFormatIconAtlas:dereference()
end

return ChartConverter