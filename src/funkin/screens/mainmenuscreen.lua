--- @class funkin.screens.MainMenuScreen : funkin.screens.MusicBeatScreen
local MainMenuScreen = MusicBeatScreen:subclass("MainMenuScreen", ...)

function MainMenuScreen:enter()
    self.persistentUpdate = true

    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic()
    end
    self.options = {
        {
            id = "storymode",
            callback = function()
                print("storymode selected")
                self:switchTo(srcreq("funkin.screens.storymenuscreen"):new())
            end
        },
        {
            id = "freeplay",
            callback = function()
                print("freeplay selected")
                self:switchTo(srcreq("funkin.screens.freeplayscreen"):new())
            end
        },
        {
            id = "options",
            callback = function()
                print("options selected")
                self:switchTo(srcreq("funkin.screens.optionsscreen"):new())
            end
        },
        {
            id = "credits",
            callback = function()
                print("credits selected")
                self:switchTo(srcreq("funkin.screens.creditsscreen"):new())
            end
        },
        {
            id = "mods",
            callback = function()
                -- i have a different plan for this menu
                print("mods selected")
            end
        }
    }
    self.curSelected = 1
    self.transitioning = false

    self.camFollow = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.camFollow)

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:follow(self.camFollow, "lockon", 0.06)
    self:addChild(self.camera)

    self.bgLayer = Parallax2D:new() --- @type comet.gfx.Parallax2D
    self.bgLayer.scrollFactor:set(0.1, 0.1)
    self.camera:addChild(self.bgLayer)

    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg"))
    self.bg.scale:set(1.175, 1.175)
    self.bg:screenCenter("xy")
    self.bgLayer:addChild(self.bg)

    self.magenta = Image:new() --- @type comet.gfx.Image
    self.magenta:loadTexture(Paths.image("menus/bg_desat"))
    self.magenta.scale:set(1.175, 1.175)
    self.magenta:screenCenter("xy")
    self.magenta:setTint(0xFFFD719B)
    self.magenta.alpha = 0
    self.bgLayer:addChild(self.magenta)

    self.grpButtons = Parallax2D:new() --- @type comet.gfx.Parallax2D
    for i = 1, #self.options do
        local buttonData = self.options[i]
        local button = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
        button:setFrameCollection(Paths.getSparrowAtlas("menus/main/" .. buttonData.id))
        button:addAnimation("idle", ("%s idle"):format(buttonData.id), 24, true)
        button:addAnimation("selected", ("%s selected"):format(buttonData.id), 24, true)
        button:playAnimation("idle")
        button.position:set(0, (i - 1) * 160)
        self.grpButtons:addChild(button)
    end
    self.grpButtons:screenCenter("xy")
    if #self.options < 4 then
        self.grpButtons.position.y = 160
    end
    self.grpButtons.scrollFactor:set(0, #self.options < 5 and 0 or (#self.options - 3) * 0.15)
    self.camera:addChild(self.grpButtons)

    self.leftWatermark = Label:new() --- @type comet.gfx.Label
    self.leftWatermark:setFont(Paths.font("fonts/vcr"))
    self.leftWatermark:setSize(16)
    self.leftWatermark:setColor(Color.WHITE)
    self.leftWatermark:setBorderColor(Color.BLACK)
    self.leftWatermark.borderSize = 1
    self.leftWatermark.text = "Garfie Engine v1.0.0-dev\nFriday Night Funkin' v0.7.5"
    self.leftWatermark.centered = false
    self.leftWatermark.position:set(5, comet.getDesiredHeight() - self.leftWatermark:getHeight() - 2)
    self:addChild(self.leftWatermark)

    self.magentaTween = nil --- @type comet.gfx.Tween

    self:changeSelection(0, true)
end

function MainMenuScreen:update(dt)
    if self.transitioning then
        return
    end
    local wheel = comet.mouse.wheel.y
    if self.controls.justPressed.UI_UP or wheel < 0 then
        self:changeSelection(-1)
    end
    if self.controls.justPressed.UI_DOWN or wheel > 0 then
        self:changeSelection(1)
    end
    if self.controls.justPressed.BACK then
        self.persistentUpdate = false
        self:switchTo(srcreq("funkin.screens.titlescreen"):new())
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
    end
    if self.controls.justPressed.ACCEPT then
        self:onSelect()
    end
    if comet.keys:wasJustPressed("f7") then
        
    end
end

function MainMenuScreen:changeSelection(by, force)
    if by == 0 and not force then
        return
    end
    self.curSelected = math.wrap(self.curSelected + by, 1, #self.options)

    for i = 1, self.grpButtons:getChildCount() do
        local button = self.grpButtons:getChild(i) --- @type comet.gfx.AnimatedImage
        if i == self.curSelected then
            local box = button:getBoundingBox(button:getTransform(true, false)) --- @type comet.math.Rect
            self.camFollow.position:set(
                self.grpButtons.position.x + button.position.x,
                self.grpButtons.position.y + button.position.y
            )
            button:playAnimation("selected")
        else
            button:playAnimation("idle")
        end
    end
    comet.mixer:play(Paths.sound("menus/sfx/scroll"))
end

function MainMenuScreen:magentaFlicker()
    if self.magentaTween then
        self.magentaTween:cancel()
    end
    self.magenta.alpha = 1

    self.magentaTween = Tween:new() --- @type comet.gfx.Tween
    self.magentaTween:target({target = self.magenta, properties = {alpha = 0}})
    self.magentaTween:start({duration = 0.12, ease = "inCirc"})
end

function MainMenuScreen:bgFlicker()
    self:magentaFlicker()
    Timer.loop(0.24, function() self:magentaFlicker() end, math.floor(1 / 0.24))
end

function MainMenuScreen:onSelect()
    if self.transitioning then
        return
    end
    self.transitioning = true

    local option = self.options[self.curSelected]
    if option.fireImmediately then
        if option.callback then
            option.callback()
        end
        return
    end
    self:bgFlicker()

    local bgScale = self.bg.scale.x
    local bgTargetScale = comet.getDesiredHeight() / self.bg:getOriginalHeight()
    local bgScroll = self.bgLayer.scrollFactor.y
    local valueStore = {num = 0.0}

    local t = Tween:new() --- @type comet.gfx.Tween
    t:target({target = valueStore, properties = {num = 1.0}})
    t:start({duration = 0.25, ease = "outBack"})
    t.onUpdate:connect(function()
        local progress = t:getEasedProgress() / 1.175

        local scale = math.lerp(bgScale, bgTargetScale, progress)
        self.bg.scale:set(scale, scale)
        self.magenta.scale:set(scale, scale)

        local scroll = math.lerp(bgScroll, 0, progress)
        self.bgLayer.scrollFactor.y = scroll
    end)
    for i = 1, self.grpButtons:getChildCount() do
        local button = self.grpButtons:getChild(i) --- @type comet.gfx.AnimatedImage
        if i == self.curSelected then
            local tmr = Timer.loop(0.06, function() button.visible = not button.visible end, math.floor(1.1 / 0.06)) --- @type comet.util.Timer
            tmr.onComplete:connect(function()
                if tmr.loopsLeft == 0 then
                    if option.callback then
                        option.callback()
                    end
                    button.visible = false
                end
            end)
        else
            local t = Tween:new() --- @type comet.gfx.Tween
            t:target({target = button, properties = {alpha = 0}})
            t:start({duration = 0.25, ease = "outQuad"})
        end
    end
    comet.mixer:play(Paths.sound("menus/sfx/select"))
end

return MainMenuScreen