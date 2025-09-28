--- @class funkin.screens.MainMenuScreen : funkin.screens.MusicBeatScreen
local MainMenuScreen = MusicBeatScreen:subclass("MainMenuScreen", ...)

function MainMenuScreen:enter()
    self.persistentUpdate = true

    self.buttons = {
        {
            id = "storymode",
            callback = function()
                print("story mode selected")
            end
        },
        {
            id = "freeplay",
            callback = function()
                print("freeplay selected")
            end
        },
        {
            id = "options",
            callback = function()
                print("options selected")
            end
        },
        {
            id = "credits",
            callback = function()
                print("credits selected")
            end
        },
        {
            id = "mods",
            callback = function()
                print("mods selected")
            end
        }
    }
    self.curSelected = 1

    self.camFollow = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.camFollow)

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.CYAN)
    self.camera:follow(self.camFollow, 0.06)
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
    self.magenta.visible = false
    self.bgLayer:addChild(self.magenta)

    self.grpButtons = Parallax2D:new() --- @type comet.gfx.Parallax2D
    for i = 1, #self.buttons do
        local buttonData = self.buttons[i]
        local button = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
        button:setFrameCollection(Paths.getSparrowAtlas("menus/main/" .. buttonData.id))
        button:addAnimation("idle", ("%s idle"):format(buttonData.id), 24, true)
        button:addAnimation("selected", ("%s selected"):format(buttonData.id), 24, true)
        button:playAnimation("idle")
        button.position:set(0, (i - 1) * 160)
        self.grpButtons:addChild(button)
    end
    self.grpButtons:screenCenter("xy")
    self.grpButtons.scrollFactor:set(0, #self.buttons < 5 and 0 or (#self.buttons - 3) * 0.15)
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

    self:changeSelection(0, true)
end

function MainMenuScreen:update(dt)
    local wheel = comet.mouse.wheel.y
    if self.controls.justPressed.UI_UP or wheel < 0 then
        self:changeSelection(-1)
    end
    if self.controls.justPressed.UI_DOWN or wheel > 0 then
        self:changeSelection(1)
    end
    if self.controls.justPressed.ACCEPT then
        if self.buttons[self.curSelected].callback then
            self.buttons[self.curSelected].callback()
        end
    end
end

function MainMenuScreen:changeSelection(by, force)
    if by == 0 and not force then
        return
    end
    self.curSelected = math.wrap(self.curSelected + by, 1, #self.buttons)

    for i = 1, self.grpButtons:getChildCount() do
        local button = self.grpButtons:getChild(i) --- @type comet.gfx.AnimatedImage
        if i == self.curSelected then
            local box = button:getBoundingBox(button:getTransform()) --- @type comet.math.Rect
            self.camFollow.position:set(box.x + (box.width * 0.5), box.y + (box.height * 0.5))
            button:playAnimation("selected")
        else
            button:playAnimation("idle")
        end
    end
    comet.mixer:play(Paths.sound("menus/sfx/scroll"))
end

return MainMenuScreen