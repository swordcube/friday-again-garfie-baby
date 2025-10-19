local AtlasTextMenu = srcreq("funkin.ui.atlastextmenu") --- @type funkin.ui.AtlasTextMenu

--- @class funkin.screens.PauseScreen : funkin.screens.MusicBeatSubScreen
local PauseScreen, super = MusicBeatSubScreen:subclass("PauseScreen")

function PauseScreen:enter()
    super.enter(self)
    self.persistentUpdate = true

    local tweens = table.copy(TweenManager.instance.tweens.children) --- @type comet.gfx.Tween[]
    for i = 1, #tweens do
        local tween = tweens[i] --- @type comet.gfx.Tween
        tween.exists = false
    end
    self.pausedTweens = tweens

    self.music = comet.mixer:load(Paths.music("breakfast")) --- @type comet.mixer.Sound
    self.music:setVolume(0)
    self.music:setLooping(true)
    self.music:play()

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.BLACK)
    self.camera:getBackgroundColor().a = 0
    self:addChild(self.camera)

    self.menu = AtlasTextMenu:new() --- @type funkin.ui.AtlasTextMenu
    self:addChild(self.menu)

    self.options = {}
    self.optionCallbacks = {}
    self:showPage("main")

    local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
    local texts = {
        game.currentChart.meta.song.title or game.currentSong,
        ("Artist: %s"):format(game.currentChart.meta.song.artist),
        ("Charter: %s"):format(game.currentChart.meta.song.charter),
        ("Difficulty: %s"):format(game.currentDifficulty:upper()),
        ("%d Blue Ball%s"):format(PlayScreen.deathCounter, PlayScreen.deathCounter == 1 and "" or "s")
    }
    for i = 1, #texts do
        local text = Label:new() --- @type comet.gfx.Label
        text:setFont(Paths.font("fonts/vcr"))
        text:setSize(32)
        text:setColor(Color.WHITE)
        text.text = texts[i]
        text.centered = false
        text.position:set(comet.getDesiredWidth() - (text:getOriginalWidth() + 20), 15 + (32 * (i - 1)))
        text.alpha = 0
        self:addChild(text)
    
        local tAlpha = Tween:new() --- @type comet.gfx.Tween
        tAlpha:target({target = text, properties = {alpha = 1}})
        tAlpha:start({duration = 0.4, ease = "inOutQuart", delay = 0.3 * i})
    
        local tPosition = Tween:new() --- @type comet.gfx.Tween
        tPosition:target({target = text.position, properties = {y = text.position.y + 5}})
        tPosition:start({duration = 0.4, ease = "inOutQuart", delay = 0.3 * i})
    end
end

function PauseScreen:addOption(name, func)
    self.options[#self.options + 1] = name
    self.optionCallbacks[#self.optionCallbacks + 1] = func
end

--- @param page "main"|"changediff"
function PauseScreen:showPage(page)
    self.options = {}
    self.optionCallbacks = {}
    
    self.menu:clearItems()

    if page == "main" then
        self:addOption("Resume", function()
            local tweens = self.pausedTweens --- @type comet.gfx.Tween[]
            for i = 1, #tweens do
                local tween = tweens[i] --- @type comet.gfx.Tween
                tween.exists = true
            end
            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()
    
            PlayScreen.instance:resumeGame()
        end)
        self:addOption("Restart Song", function()
            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()
    
            PlayScreen.instance:switchTo(function()
                PlayScreen.resetStatics()
                return PlayScreen:new()
            end)
        end)
        local diffs = PlayScreen.instance.currentChart.meta.song.difficulties --- @type string
        if #diffs > 1 then
            self:addOption("Change Difficulty", function()
                self:showPage("changediff")
            end)
        end
        self:addOption("Exit to Menu", function()
            self.persistentUpdate = false
            self.persistentDraw = false
            self:close()
    
            PlayScreen.instance:endSong()
        end)
    elseif page == "changediff" then
        local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
        local diffs = game.currentChart.meta.song.difficulties --- @type string

        for i = 1, #diffs do
            local diff = diffs[i]
            self:addOption(diff, function()
                local params = PlayScreen.static.lastParams
                params.difficulty = diff

                self.persistentUpdate = false
                self.persistentDraw = false
                self:close()
        
                PlayScreen.instance:switchTo(function()
                    PlayScreen.resetStatics()
                    return PlayScreen:new(params)
                end)
            end)
        end
        self:addOption("Back", function()
            self:showPage("main")
        end)
    end
    for i = 1, #self.options do
        local option = self.options[i]
        self.menu:addItem(option)
    end
end

function PauseScreen:update(dt)
    if self.music:getVolume() < 0.5 then
        self.music:setVolume(math.min(self.music:getVolume() + (dt * 0.05), 0.5))
    end
    local bgColor = self.camera:getBackgroundColor()
    if bgColor.a < 0.6 then
        bgColor.a = math.min(bgColor.a + (dt * 1.0), 0.6)
    end
end

function PauseScreen:input(_)
    if self.controls.justPressed.ACCEPT then
        self.controls.justPressed.ACCEPT = false -- #hack, respectable tho lol -swordcube
        self.optionCallbacks[self.menu.curSelected]()
    end
end

function PauseScreen:exit()
    super.exit(self)

    self.music:stop()
    self.music = nil

    self.menu.active = false
end

return PauseScreen