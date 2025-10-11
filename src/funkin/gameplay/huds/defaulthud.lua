local BaseHUD = srcreq("funkin.gameplay.huds.basehud") --- @type funkin.gameplay.huds.BaseHUD
local HealthIcon = srcreq("funkin.gameplay.ui.healthicon") --- @type funkin.gameplay.ui.HealthIcon

--- @class funkin.gameplay.huds.DefaultHUD : funkin.gameplay.huds.BaseHUD
local DefaultHUD, super = BaseHUD:subclass("DefaultHUD", ...)

-- TODO: the pixel icons randomly disappear for one frame sometimes and i have no clue why

function DefaultHUD:__init__(playField)
    super.__init__(self, playField, "funkin")

    self.healthBarBG = Image:new() --- @type comet.gfx.Image
    self.healthBarBG:loadTexture(self:getHUDImage("healthBar"))
    self.healthBarBG:screenCenter("x")
    self.healthBarBG.position.y = Options.downscroll and 80 or comet.getDesiredHeight() * 0.9
    self:addChild(self.healthBarBG)

    self.healthBar = ProgressBar:new() --- @type comet.gfx.ProgressBar
    self.healthBar:setEmptyColor(Color.RED)
    self.healthBar:setFillColor(Color.LIME)
    self.healthBar.size:set(self.healthBarBG:getWidth() - 8, self.healthBarBG:getHeight() - 8)
    self.healthBar.position.y = self.healthBarBG.position.y
    self.healthBar:screenCenter("x")
    self.healthBar.fillStyle = "right-to-left"
    self:addChild(self.healthBar)

    local chars = self.playField.currentChart.meta.game.characters
    self.iconP2 = HealthIcon:new(chars.opponent or "face", false) --- @type funkin.gameplay.ui.HealthIcon
    self.iconP2.position.y = self.healthBar.position.y
    self:addChild(self.iconP2)

    self.iconP1 = HealthIcon:new(chars.player or "face", true) --- @type funkin.gameplay.ui.HealthIcon
    self.iconP1.position.y = self.healthBar.position.y
    self:addChild(self.iconP1)

    self.scoreText = Label:new() --- @type comet.gfx.Label
    self.scoreText:setFont(Paths.font("fonts/vcr"))
    self.scoreText.position.x = self.healthBar.position.x + 110
    self.scoreText.position.y = self.healthBar.position.y + 20
    self.scoreText.alignment = "right"
    self.scoreText.centered = false
    self.scoreText.borderSize = 1
    self.scoreText:setBorderColor(Color.BLACK)
    self.scoreText:setSize(16)
    self.scoreText:setColor(Color.WHITE)
    self.scoreText.text = "Score: 0"
    self:addChild(self.scoreText)

    self.iconProg = 0.0
    self:updateIcons()
end

function DefaultHUD:updateHealthBar(health, min, max)
    local percent = health / max
    self.iconP2:setHealth(1 - percent)
    self.iconP1:setHealth(percent)

    self:updateIcons()
end

function DefaultHUD:updatePlayerStats(stats)
    self.scoreText.text = ("Score: %s"):format(math.formatMoney(stats.score, false, true))
end

function DefaultHUD:updateIcons()
    local progress = 1 - self.healthBar:getProgress()
    local baseX = self.healthBar.position.x - (self.healthBar:getWidth() * 0.5)

    self.iconP2.position.x = baseX + (self.healthBar:getWidth() * progress) - (self.iconP2:getWidth() * 0.5) + 26
    self.iconP1.position.x = baseX + (self.healthBar:getWidth() * progress) + (self.iconP1:getWidth() * 0.5) - 26
end

function DefaultHUD:update(dt)
    super.update(self, dt)
    self.healthBar:setProgress(math.lerp(self.healthBar:getProgress(), self.playField.stats.health / self.playField.stats.maxHealth, dt * 10))

    self.iconProg = self.iconProg - (dt * 6)
    if self.iconProg < 0.0 then
        self.iconProg = 0.0
    end
    local scale = math.abs(1 + ((1 - Ease.outSine(1 - self.iconProg)) * 0.2))
    if self.iconP2:getOriginalWidth() > self.iconP2:getOriginalHeight() then
        self.iconP2:setGraphicSize(math.floor(150 * scale), 0)
    else
        self.iconP2:setGraphicSize(0, math.floor(150 * scale))
    end
    if self.iconP1:getOriginalWidth() > self.iconP1:getOriginalHeight() then
        self.iconP1:setGraphicSize(math.floor(150 * scale), 0)
    else
        self.iconP1:setGraphicSize(0, math.floor(150 * scale))
    end
    self:updateIcons()
end

function DefaultHUD:beatHit(b)
    self.iconP2.scale:set(1.2, 1.2)
    self.iconP1.scale:set(1.2, 1.2)

    self.iconProg = 1
    self:updateIcons()
end

return DefaultHUD