local fs = love.filesystem

--- @class funkin.screens.TitleScreen : funkin.screens.MusicBeatScreen
local TitleScreen, super = MusicBeatScreen:extend("TitleScreen", ...)

TitleScreen.initialized = false

-- TODO: the hue shader & cheat code thingie

function TitleScreen:enter()
    super.enter(self)
    self.persistentUpdate = true
    
    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic(0)

        comet.mixer.music:pause()
        comet.mixer.music:seek(0.0)
        comet.mixer.music:play()
        
        comet.mixer.music:fadeIn(4, 0, 1)
    end
    self.hueShader = Shader:new(Paths.frag("hue_offset")) --- @type comet.gfx.Shader
    self.hueShader:send("OFFSET", 0)

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.TRANSPARENT)
    self.camera:setShaders({self.hueShader})
    self:addChild(self.camera)

    local availableQuotes = CoolUtil.parseCSV(fs.getContent(Paths.csv("menus/title/quotes")))
    self.chosenQuotes = availableQuotes[math.floor(love.math.random(1, #availableQuotes))]

    self.introSequence = {
        [1]  = {lines = {"The", "Funkin Crew Inc"}},
        [3]  = {lines = {"The", "Funkin Crew Inc", "Presents"}},
        [4]  = {lines = {}},
        [5]  = {lines = {"In association", "with"}},
        [7]  = {lines = {"In association", "with", "Newgrounds"}, callback = function() self.ngSpr:revive() end},
        [8]  = {lines = {}, callback = function() self.ngSpr:kill() end},
        [9]  = {lines = {self.chosenQuotes[1]}},
        [11] = {lines = self.chosenQuotes},
        [12] = {lines = {}},
        [13] = {lines = {"Friday"}},
        [14] = {lines = {"Friday", "Night"}},
        [15] = {lines = {"Friday", "Night", "Funkin"}}
    }
    self.introLength = 16
    
    self.skippedIntro = false
    self.transitioning = false
    
    self.titleGroup = Object:new() --- @type comet.core.Object
    self.titleGroup:kill()
    self.camera:addChild(self.titleGroup)
    
    self.gf = AnimatedImage:new(comet.getDesiredWidth() * 0.4, comet.getDesiredHeight() * 0.07) --- @type comet.gfx.AnimatedImage
    self.gf:setFrameCollection(Paths.getSparrowAtlas("menus/title/gf"))
    self.gf.animation:addByIndices("danceLeft", "gfDance", table.numberList(1, 15), 24, false)
    self.gf.animation:addByIndices("danceRight", "gfDance", table.numberList(16, 31), 24, false)
    self.gf.animation:play("danceLeft")
    self.gf.centered = false
    self.titleGroup:addChild(self.gf)

    self.logo = AnimatedImage:new(-150, -100) --- @type comet.gfx.AnimatedImage
    self.logo:setFrameCollection(Paths.getSparrowAtlas("menus/title/logo"))
    self.logo.animation:addByName("idle", "logo bumpin", 24, false)
    self.logo.animation:play("idle")
    self.logo.centered = false
    self.titleGroup:addChild(self.logo)

    self.titleText = AnimatedImage:new(100, comet.getDesiredHeight() * 0.8) --- @type comet.gfx.AnimatedImage
    self.titleText:setFrameCollection(Paths.getSparrowAtlas("menus/title/enter"))
    self.titleText.animation:addByName("idle", "Press Enter to Begin", 24, true)
    self.titleText.animation:addByName("press", "ENTER PRESSED", 24, true)
    self.titleText.animation:play("idle")
    self.titleText.centered = false
    self.titleGroup:addChild(self.titleText)
    
    self.quoteText = AtlasText:new(0, 155, "bold", 1, "") --- @type funkin.ui.AtlasText
    self.quoteText:setAlignment("center")
    self.quoteText:screenCenter("x")
    self.camera:addChild(self.quoteText)

    self.ngSpr = Image:new() --- @type comet.gfx.Image
    self.ngSpr:loadTexture(Paths.image("menus/title/newgrounds")) -- TODO: the other variants
    self.ngSpr.centered = false
    self.ngSpr.scale:set(0.8, 0.8)
    self.ngSpr:screenCenter("x")
    self.ngSpr.position.y = comet.getDesiredHeight() * 0.52
    self.ngSpr:kill()
    self.camera:addChild(self.ngSpr)

    self.pressTimer = nil --- @type comet.util.Timer
    
    if TitleScreen.initialized then
        self:skipIntro()
    end
end

function TitleScreen:update(dt)
    super.update(self, dt)
    if self.controls.pressed.UI_LEFT then
        self.hueShader:send("OFFSET", self.hueShader:getUniformNumber("OFFSET") - (dt * 0.1))
    end
    if self.controls.pressed.UI_RIGHT then
        self.hueShader:send("OFFSET", self.hueShader:getUniformNumber("OFFSET") + (dt * 0.1))
    end
    if self.controls.justPressed.ACCEPT then
        if not self.skippedIntro then
            self:skipIntro()
        
        elseif not self.transitioning then
            self.transitioning = true
            
            self.camera:flash(Color.WHITE, 1)
            comet.mixer:play(Paths.sound("menus/sfx/select"))
            
            self.titleText.animation:play("press")
            self.pressTimer = Timer.wait(2, function()
                self.persistentUpdate = false
                self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
            end)
        
        elseif not self.showingTransition then
            if self.pressTimer then
                self.pressTimer:cancel()
                self.pressTimer = nil
            end
            self.persistentUpdate = false
            self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
        end
    end
end

function TitleScreen:skipIntro()
    if self.skippedIntro then
        return
    end
    self.skippedIntro = true
    
    self.quoteText:kill()
    self.ngSpr:kill()
    
    self.titleGroup:revive()
    self.camera:flash(Color.WHITE, TitleScreen.initialized and 1 or 4)
    
    TitleScreen.initialized = true
end

function TitleScreen:beatHit(beat)
    if not self.skippedIntro then
        if beat >= self.introLength then
            self:skipIntro()
        else
            local step = self.introSequence[beat]
            if step then
                self.quoteText:setText(table.concat(step.lines, "\n"))
                self.quoteText:screenCenter("x")
                if step.callback then
                    step.callback()
                end
            end
        end
    end
    if beat % 2 == 0 then
        self.gf.animation:play("danceRight")
    else
        self.gf.animation:play("danceLeft")
    end
    self.logo.animation:play("idle", true)
    super.beatHit(self, beat)
end

return TitleScreen