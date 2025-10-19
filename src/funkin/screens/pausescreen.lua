local AtlasTextMenu = srcreq("funkin.ui.atlastextmenu") --- @type funkin.ui.AtlasTextMenu

--- @class funkin.screens.PauseScreen : funkin.screens.MusicBeatSubScreen
local PauseScreen, super = MusicBeatSubScreen:subclass("PauseScreen")

function PauseScreen:enter()
    super.enter(self)
    self.persistentUpdate = true

    self.music = comet.mixer:load(Paths.music("breakfast")) --- @type comet.mixer.Sound
    self.music:setVolume(0)
    self.music:setLooping(true)
    self.music:play()

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.BLACK)
    self.camera._bgColor.a = 0
    self:addChild(self.camera)

    self.menu = AtlasTextMenu:new() --- @type funkin.ui.AtlasTextMenu
    self:addChild(self.menu)

    self.options = {
        "Resume Song",
        "Restart Song",
        "Exit to menu"
    }
    self.optionCallbacks = {
        function()
            print("resume selected")

            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()

            PlayScreen.instance:resumeGame()
        end,
        function()
            print("restart selected")

            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()

            PlayScreen.instance:switchTo(srcreq("funkin.screens.playscreen"):new())
        end,
        function()
            print("exit selected")

            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()

            PlayScreen.instance:endSong()
        end
    }

    for i = 1, #self.options do
        local option = self.options[i]
        self.menu:addItem(option)
    end

    local songTitle = nil
    if PlayScreen.instance.currentChart.meta.song.title then
        songTitle = PlayScreen.instance.currentChart.meta.song.title
    else
        songTitle = PlayScreen.instance.currentSong
    end

    self.songText = Label:new() --- @type comet.gfx.Label
    self.songText:setFont(Paths.font("fonts/vcr"))
    self.songText:setSize(32)
    self.songText:setColor(Color.WHITE)
    self.songText.text = songTitle
    self.songText.centered = false
    self.songText.position:set(comet.getDesiredWidth() - (self.songText:getOriginalWidth() + 20), 15)
    self.songText.alpha = 0
    self:addChild(self.songText)

    local tAlpha = Tween:new() --- @type comet.gfx.Tween
    tAlpha:target({target = self.songText, properties = {alpha = 1}})
    tAlpha:start({duration = 0.4, ease = "inOutQuart"})

    local tPosition = Tween:new() --- @type comet.gfx.Tween
    tPosition:target({target = self.songText.position, properties = {y = self.songText.position.y + 5}})
    tPosition:start({duration = 0.4, ease = "inOutQuart"})
end

function PauseScreen:update(dt)
    if self.music:getVolume() < 0.5 then
        self.music:setVolume(self.music:getVolume() + 0.01 * dt)
    end

    if self.camera._bgColor.a < 0.6 then
        self.camera._bgColor.a = self.camera._bgColor.a + 1 * dt
    end
end

function PauseScreen:input(_)
    if self.controls.justPressed.ACCEPT then
        self.music:stop()
        self.music = nil

        self.controls.justPressed.ACCEPT = false
        self.menu.active = false
        self.optionCallbacks[self.menu.curSelected]()
    end
end

return PauseScreen