local Stage = srcreq("funkin.gameplay.stage") --- @type funkin.gameplay.Stage

local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin
local UISkin = srcreq("funkin.gameplay.ui.uiskin") --- @type funkin.gameplay.ui.UISkin

local Scoring = srcreq("funkin.gameplay.scoring") --- @type funkin.gameplay.Scoring
local PlayField = srcreq("funkin.gameplay.playfield") --- @type funkin.gameplay.PlayField

--- @class funkin.screens.PlayScreen : funkin.screens.MusicBeatScreen
local PlayScreen, super = MusicBeatScreen:subclass("PlayScreen", ...)

PlayScreen.static.instance = nil --- @type funkin.screens.PlayScreen

function PlayScreen:__init__(params)
    super.__init__(self)
    PlayScreen.static.instance = self

    self.currentSong = params.song
    self.currentDifficulty = params.difficulty
    self.currentMix = params.mix or "default"
    self.parentContentPack = params.contentPack
end

function PlayScreen:enter()
    self.persistentUpdate = true

    self.startingSong = true
    self.endingSong = false

    self.camGame = Camera:new() --- @type comet.gfx.Camera
    self.camGame:setBackgroundColor(Color.TRANSPARENT)
    self:addChild(self.camGame)

    self.camHUD = Camera:new() --- @type comet.gfx.Camera
    self.camHUD:setBackgroundColor(Color.TRANSPARENT)
    self:addChild(self.camHUD)

    self.camOther = Camera:new() --- @type comet.gfx.Camera
    self.camOther:setBackgroundColor(Color.TRANSPARENT)
    self:addChild(self.camOther)

    comet.mixer.music:stop()
    comet.mixer.music:setSource(Paths.inst(self.currentSong, self.currentMix, self.parentContentPack))
    comet.mixer.music:setLooping(false)
    comet.mixer.music:setVolume(1.0)

    self.inst = comet.mixer.music
    self.inst.onComplete:connect(function()
        self:endSong()
    end)
    self.currentChart = CoolUtil.parseJson(Paths.json(("songs/%s/%s/chart"):format(self.currentSong, self.currentMix), self.parentContentPack))
    self.currentChart.meta = CoolUtil.parseJson(Paths.json(("songs/%s/%s/metadata"):format(self.currentSong, self.currentMix), self.parentContentPack))
    
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    c.music = nil
    c.offset = 50
    c:reset(self.currentChart.meta.song.timingPoints[1].b, self.currentChart.meta.song.timingPoints[1].ts)
    c:setupTimingPoints(self.currentChart.meta.song.timingPoints)
    c:setCurrentRawTime(c:getCurrentBeatLength() * -5)

    --- Controls how many beats it will take to bop the camera
    self.camZoomingInterval = -1
    
    --- How many beats it has taken to bop the camera
    self.camZoomingOffset = -1

    --- The default zoom for the game camera
    self.defaultCamZoom = 1

    --- The default zoom for the hud camera
    self.defaultHUDZoom = 1

    --- Multipler for how fast the camera should zoom back to default, `1` being instantaneously and `0` being not at all
    self.camZoomingSpeed = 0.05

    self.stage = Stage:new() --- @type funkin.gameplay.Stage
    self:addChild(self.stage)

    local fadeShader = Shader:new(Paths.frag("gradient_fade")) --- @type comet.gfx.Shader
    fadeShader:reference()

    local test = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
    test:setFrameCollection(Paths.getSparrowAtlas("game/characters/bf/sprite"))
    test:addAnimationByName("idle", "BF idle dance", 24, true)
    test:playAnimation("idle")
    test.scale:set(0.5, 0.5)
    test.centered = false
    test.onDraw = function(_)
        local prevAlpha = test.alpha
        test.flipY = not test.flipY
        test.alpha = 0.5 * prevAlpha
        test.position.y = test.position.y + (test:getHeight(1) - 10)
        fadeShader:send("quad", {test._frame.quad:getViewport()})
        test:setShader(fadeShader)
        test:_draw()
        
        test.flipY = not test.flipY
        test.alpha = prevAlpha
        test.position.y = test.position.y - (test:getHeight(1) - 10)
        test:setShader()
        test:_draw()
    end
    local old = test.destroy
    test.destroy = function(o)
        fadeShader:dereference()
        old(o)
    end
    self:addChild(test)

    Scoring.resetSystem()
    
    NoteSkin.clearCache()
    UISkin.clearCache()

    -- preload current note & ui skin
    NoteSkin.get(self.currentChart.meta.game.noteSkin)
    UISkin.get(self.currentChart.meta.game.uiSkin)

    local tracks = self.currentChart.meta.song.tracks
    if tracks then
        local tempTracks = {}
        for i = 1, #tracks.opponent do
            local track = tracks.opponent[i]
            tempTracks[#tempTracks + 1] = Paths.vocalTrack(self.currentSong, self.currentMix, track, self.parentContentPack)
        end
        for i = 1, #tracks.player do
            local track = tracks.player[i]
            tempTracks[#tempTracks + 1] = Paths.vocalTrack(self.currentSong, self.currentMix, track, self.parentContentPack)
        end
        for i = 1, #tracks.spectator do
            local track = tracks.spectator[i]
            tempTracks[#tempTracks + 1] = Paths.vocalTrack(self.currentSong, self.currentMix, track, self.parentContentPack)
        end
        tracks = tempTracks
    else
        tracks = {
            Paths.vocalTrack(self.currentSong, self.currentMix, "vocals-" .. self.currentChart.meta.game.characters.opponent, self.parentContentPack),
            Paths.vocalTrack(self.currentSong, self.currentMix, "vocals-" .. self.currentChart.meta.game.characters.player, self.parentContentPack)
        }
    end
    self.vocalTracks = {}

    for i = 1, #tracks do
        local track = comet.mixer:load(tracks[i])
        track:setPitch(1)
        track:seek(0)
        table.insert(self.vocalTracks, track)
    end
    self.inst:setPitch(1)
    self.inst:seek(0)

    self.playField = PlayField:new() --- @type funkin.gameplay.PlayField
    self.playField:prepareChart(self.currentChart, self.currentDifficulty)
    self.camHUD:addChild(self.playField)

    local hud = srcreq("funkin.gameplay.huds.defaulthud"):new(self.playField) --- @type funkin.gameplay.huds.BaseHUD
    hud:updatePlayerStats(self.playField.stats)

    self.playField.hud = hud
    self.playField:insertChild(1, hud)
end

function PlayScreen:addChild(object, tag, camera)
    if not self.inst then
        super.addChild(self, object, tag)
        return
    end
    if not camera then
        camera = self.camGame
    end
    camera:addChild(object, tag)
end

function PlayScreen:update(dt)
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    if self.startingSong and c:getCurrentRawTime() >= 0.0 then
        self:startSong()
    end
    local gz, hz = self.defaultCamZoom, self.defaultHUDZoom
    local ratio = math.getElapsedLerp(self.camZoomingSpeed, dt)
    self.camGame.zoom:lerp(gz, gz, ratio)
    self.camHUD.zoom:lerp(hz, hz, ratio)
end

function PlayScreen:startSong()
    self.startingSong = false
    
    self.inst:play()
    Conductor.instance.music = self.inst

    for i = 1, #self.vocalTracks do
        self.vocalTracks[i]:play()
    end
end

function PlayScreen:endSong()
    self:switchTo(srcreq("funkin.screens.freeplayscreen"):new())
end

function PlayScreen:beatHit(beat)
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor

    local zoomInterval = self.camZoomingInterval >= 0 and self.camZoomingInterval or c:getCurrentTimeSignature()[1]
    local beatOffset = self.camZoomingOffset >= 0 and beat + self.camZoomingOffset or math.floor(beat - c._latestTimingPoint.beat)

    if beat > 0 and beatOffset % zoomInterval == 0 then
        self.camGame.zoom:set(self.camGame.zoom.x + 0.015, self.camGame.zoom.y + 0.015)
        self.camHUD.zoom:set(self.camHUD.zoom.x + 0.03, self.camHUD.zoom.y + 0.03)
    end
end

function PlayScreen:exit()
    local tracks = self.vocalTracks
    for i = 1, #tracks do
        tracks[i]:destroy()
    end
    self.vocalTracks = {}

    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    c.offset = 0
    
    PlayScreen.static.instance = nil
end

return PlayScreen