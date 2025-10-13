local StrumLine = srcreq("funkin.gameplay.notes.strumline") --- @type funkin.gameplay.notes.StrumLine
local NoteField = srcreq("funkin.gameplay.notes.notefield") --- @type funkin.gameplay.notes.NoteField

local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin
local NoteSplash = srcreq("funkin.gameplay.notes.notesplash") --- @type funkin.gameplay.notes.NoteSplash

local Scoring = srcreq("funkin.gameplay.scoring") --- @type funkin.gameplay.Scoring
local ScoreDisplay = srcreq("funkin.gameplay.ui.scoredisplay") --- @type funkin.gameplay.ui.ScoreDisplay

--- @class funkin.gameplay.PlayField : comet.gfx.Object2D
local PlayField, super = Object2D:subclass("PlayField", ...)

local math = math
local upperDirs = {"LEFT", "DOWN", "UP", "RIGHT"}

function PlayField:__init__()
    super.__init__(self)

    self.currentChart = nil
    self.currentDifficulty = "unknown"

    self.stats = {
        health = 0.5,
        
        minHealth = 0,
        maxHealth = 1,

        ratings = {
            killer = 0,
            sick = 0,
            good = 0,
            bad = 0,
            shit = 0
        },
        combo = 0,
        missCombo = 0,

        comboBreaks = 0,
        misses = 0,

        accuracyScore = 0,
        totalNotesHit = 0,

        score = 0,
        accuracy = 0,
    }
    self.scoreDisplay = ScoreDisplay:new(comet.getDesiredWidth() * 0.55, comet.getDesiredHeight() * 0.5) --- @type funkin.gameplay.ui.ScoreDisplay
    self:addChild(self.scoreDisplay)

    self.strumLines = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.strumLines)

    local downscroll = Options.downscroll
    self.hud = nil --- @type funkin.gameplay.huds.BaseHUD

    self.opponentStrumLine = StrumLine:new(comet.getDesiredWidth() * 0.25, downscroll and comet.getDesiredHeight() - 100 or 100, downscroll) --- @type funkin.gameplay.notes.StrumLine
    self.opponentStrumLine.botplay = true
    self.strumLines:addChild(self.opponentStrumLine)
    
    self.playerStrumLine = StrumLine:new(comet.getDesiredWidth() * 0.75, downscroll and comet.getDesiredHeight() - 100 or 100, downscroll) --- @type funkin.gameplay.notes.StrumLine
    self.playerStrumLine.botplay = false
    self.strumLines:addChild(self.playerStrumLine)

    self.notes = NoteField:new() --- @type funkin.gameplay.notes.NoteField
    self.notes.playField = self
    self:addChild(self.notes)

    self.splashes = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.splashes)

    self.opponentUnderlay = Rectangle:new(self.opponentStrumLine.position.x) --- @type comet.gfx.Rectangle
    self.opponentUnderlay.size:set(468, comet.getDesiredHeight())
    self.opponentUnderlay:setColor(Color.BLACK)
    self.opponentUnderlay:screenCenter("y")
    self.opponentUnderlay.alpha = Options.laneUnderlay
    self:insertChild(2, self.opponentUnderlay)

    self.playerUnderlay = Rectangle:new(self.playerStrumLine.position.x) --- @type comet.gfx.Rectangle
    self.playerUnderlay.size:set(468, comet.getDesiredHeight())
    self.playerUnderlay:setColor(Color.BLACK)
    self.playerUnderlay:screenCenter("y")
    self.playerUnderlay.alpha = Options.laneUnderlay
    self:insertChild(2, self.playerUnderlay)

    -- atlases to deref when this playfield is destroyed
    self.atlasCache = {} --- @type table<string, comet.gfx.FrameCollection>

    local splashy = Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.playerStrumLine.skin, NoteSkin.get(self.playerStrumLine.skin).splash.atlas.path))
    self:cacheAtlas(("#_SPLASH_%s"):format(self.playerStrumLine.skin), splashy)
end

function PlayField:cacheAtlas(id, atlas)
    if self.atlasCache[id] or not atlas then
        return
    end
    atlas:reference()
    self.atlasCache[id] = atlas
end

function PlayField:prepareChart(chart, difficulty)
    self.currentChart = chart
    for _, notes in pairs(chart.n) do
        table.sort(notes, function(a, b)
            if a.t ~= b.t then
                return a.t < b.t
            end
            return a.d < b.d
        end)
    end
    self.notes.pendingNotes = chart.n[difficulty]
    self.notes.curNoteIndex = 1

    for i = 1, self.strumLines:getChildCount() do
        self.strumLines:getChild(i).scrollSpeed = chart.meta.game.scrollSpeed[difficulty] or 1.0
    end
    self.scoreDisplay:loadSkin(chart.meta.game.uiSkin)
end

--- @param note funkin.gameplay.notes.Note
function PlayField:hitNote(note)
    note.wasHit = true
    note:destroy()

    local strum = note.strumLine:getChild(note.lane + 1) --- @type funkin.gameplay.notes.Strum
    strum:glow(note.strumLine.botplay)

    if note.strumLine == self.playerStrumLine then
        self.stats.combo = self.stats.combo + 1
        self.stats.missCombo = 0

        local rating = Scoring.judgeNote(note.time, Conductor.instance:getCurrentTime())
        self.scoreDisplay:showRating(rating)
        self.scoreDisplay:showCombo(self.stats.combo)

        self.stats.score = self.stats.score + Scoring.scoreNote(note.time, Conductor.instance:getCurrentTime())
        self.stats.health = math.clamp(self.stats.health + 0.0115, self.stats.minHealth, self.stats.maxHealth)

        if Scoring.hasNoteSplash(rating) then
            self:showNoteSplash(note.lane, note.skin, note.strumLine)
        end
        if self.hud then
            self.hud:updateHealthBar(self.stats.health, self.stats.minHealth, self.stats.maxHealth)
            self.hud:updatePlayerStats(self.stats)
        end
        local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
        if game then
            game.curCameraTarget = 2
            game.player:playSingAnimation(note.lane)
        end
        
    elseif note.strumLine == self.opponentStrumLine then
        local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
        if game then
            game.curCameraTarget = 1
            game.opponent:playSingAnimation(note.lane)
        end
    end
end

--- @param lane      integer
--- @param skin      string
--- @param strumLine funkin.gameplay.notes.StrumLine
function PlayField:showNoteSplash(lane, skin, strumLine)
    local splash = NoteSplash:new() --- @type funkin.gameplay.notes.NoteSplash
    splash.playField = self
    splash:setup(lane, skin, strumLine)
    self.splashes:addChild(splash)
end

--- @param note funkin.gameplay.notes.Note
function PlayField:missNote(note)
    note:destroy()

    if note.strumLine == self.playerStrumLine then
        if self.stats.combo > 0 then
            self.stats.combo = 0
            self.stats.comboBreaks = self.stats.comboBreaks + 1
        end
        self.stats.missCombo = self.stats.missCombo + 1

        self.stats.score = self.stats.score - 100
        self.stats.health = math.clamp(self.stats.health - 0.02375, self.stats.minHealth, self.stats.maxHealth)
        
        if self.hud then
            self.hud:updateHealthBar(self.stats.health, self.stats.minHealth, self.stats.maxHealth)
            self.hud:updatePlayerStats(self.stats)
        end
        self.scoreDisplay:showRating("miss")
        self.scoreDisplay:showCombo(self.stats.missCombo, true)

        local game = PlayScreen.instance --- @type funkin.screens.PlayScreen
        if game then
            game.player:playMissAnimation(note.lane)
        end
    end
end

function PlayField:input(e)
    local plr = self.playerStrumLine
    if plr.botplay or e.isRepeat or e.type == "text" then
        return
    end
    local lane = -1
    local controls = Controls.instance --- @type funkin.backend.Controls
    
    for i = 1, plr.keyCount do
        local mappings = controls:getMappings()["NOTE_" .. upperDirs[i]]
        for j = 1, #mappings do
            local m = mappings[j]
            if m.type == "key" and m.key == e.key then
                lane = i - 1
                break
            end
        end
    end
    if lane == -1 then
        return
    end
    if e.pressed then
        local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
        local validNotes = table.filter(self.notes.children, function(n)
            return n and not n.wasHit and math.abs(n.time - c:getCurrentTime()) <= 216 and n.strumLine == plr and n.lane == lane
        end)
        table.sort(validNotes, function(a, b)
            return a.time < b.time
        end)
        local note = validNotes[1] --- @type funkin.gameplay.notes.Note
        local strum = plr:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
        if note then
            self:hitNote(note)
        else
            strum:playAnimation("press", true)
        end
    else
        local strum = plr:getChild(lane + 1) --- @type funkin.gameplay.notes.Strum
        strum:playAnimation("static", true)
    end
end

function PlayField:destroy()
    super.destroy(self)
    for _, ass in pairs(self.atlasCache) do
        ass:dereference()
    end
end

return PlayField