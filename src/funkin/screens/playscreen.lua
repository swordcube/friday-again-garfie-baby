local Path = cometreq("util.path") --- @type comet.util.Path

local Stage = srcreq("funkin.gameplay.stage") --- @type funkin.gameplay.Stage
local CharacterConfig = srcreq("funkin.gameplay.character.config") --- @type funkin.gameplay.character.Config

local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin
local UISkin = srcreq("funkin.gameplay.ui.uiskin") --- @type funkin.gameplay.ui.UISkin

local Scoring = srcreq("funkin.gameplay.scoring") --- @type funkin.gameplay.Scoring
local PlayField = srcreq("funkin.gameplay.playfield") --- @type funkin.gameplay.PlayField

local Script = srcreq("funkin.scripting.script") --- @type funkin.scripting.Script
local ScriptPack = srcreq("funkin.scripting.scriptpack") --- @type funkin.scripting.ScriptPack

--- @class funkin.screens.PlayScreen : funkin.screens.MusicBeatScreen
local PlayScreen, super = MusicBeatScreen:subclass("PlayScreen", ...)

PlayScreen.static.instance = nil --- @type funkin.screens.PlayScreen
PlayScreen.static.lastParams = nil

function PlayScreen:__init__(params)
    super.__init__(self)
    
    if PlayScreen.static.lastParams then
        params = PlayScreen.static.lastParams
    end
    PlayScreen.static.lastParams = params
    
    self.currentSong = params.song
    self.currentDifficulty = params.difficulty
    self.currentMix = params.mix or "default"
    self.parentContentPack = params.contentPack
end

function PlayScreen:enter()
    PlayScreen.static.instance = self
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

    CharacterConfig.clearCache()

    self.scripts = ScriptPack:new() --- @type funkin.scripting.ScriptPack
    self.scripts:linkObject(self)

    self.stage = Stage:new(self.currentChart.meta.game.stage) --- @type funkin.gameplay.Stage
    self:addChild(self.stage)

    local directoriesToIterate = {
        "game/scripts",
        ("songs/%s/%s/scripts"):format(self.currentSong, self.currentMix)
    }
    for i = 1, #directoriesToIterate do
        Paths.iterateDirectory(directoriesToIterate[i], function(itemPath)
            if table.contains(Paths.SCRIPT_EXTS, "." .. Path.extension(itemPath)) then
                FLog.verbose("Loading script: " .. itemPath)
                local scr = Script:new(itemPath) --- @type funkin.scripting.Script
                self.scripts:add(scr)
            end
        end, true)
    end
    self.scripts:call("onEnter")
    self.scripts:call("onCreate")

    local initCamPos = self.stage.config.initialCamPos or {0, 0}
    self.spectator = self.stage.props.spectator --- @type funkin.gameplay.Character
    self.opponent = self.stage.props.opponent --- @type funkin.gameplay.Character
    self.player = self.stage.props.player --- @type funkin.gameplay.Character

    --- Determines which character the camera should focus on
    --- - `1` focuses on opponent
    --- - `2` focuses on player
    --- - `3` focuses on spectator
    self.curCameraTarget = 1

    self.camFollow = Object2D:new() --- @type comet.gfx.Object2D
    self.camFollow.position:set(initCamPos[1], initCamPos[2])
    self:addChild(self.camFollow)

    self.camGame:follow(self.camFollow, "lockon", 0.05)
    self.camGame:snapToTarget()

    self.defaultCamZoom = self.stage.config.zoom
    self.camGame.zoom:set(self.defaultCamZoom, self.defaultCamZoom)

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
    self.playField:insertChild(4, hud)
end

function PlayScreen:postEnter()
    self.scripts:call("onEnterPost")
    self.scripts:call("onCreatePost")
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

function PlayScreen:resyncVocals()
    for i = 1, #self.vocalTracks do
        local track = self.vocalTracks[i] --- @type comet.mixer.Sound
        track:seek(self.inst:tell())
    end
    self.scripts:call("onResyncVocals")
end

function PlayScreen:_update(dt)
    self.scripts:call("onUpdate", dt)
    super._update(self, dt)
    self.scripts:call("onUpdatePost", dt)
end

function PlayScreen:update(dt)
    if comet.isDebug() then
        if comet.keys:wasJustPressed("h") then
            self.camHUD.visible = not self.camHUD.visible
        end
        if comet.mouse.wheel.y ~= 0 then
            self.defaultCamZoom = self.defaultCamZoom - ((comet.mouse.wheel.y * 0.1) * self.defaultCamZoom)
        end
    end
    local focusedCharacter = self.opponent
    if self.curCameraTarget == 2 then
        focusedCharacter = self.player
    elseif self.curCameraTarget == 3 then
        focusedCharacter = self.spectator
    end
    local camX, camY = focusedCharacter:getCameraPosition()
    self.camFollow.position:set(camX, camY)

    if not self.startingSong and not self.endingSong then
        for i = 1, #self.vocalTracks do
            local track = self.vocalTracks[i] --- @type comet.mixer.Sound
            if math.abs(track:tell() - self.inst:tell()) > 30 then
                self:resyncVocals()
                break
            end
        end
    end
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
    self.scripts:call("onStartSong")
    self.scripts:call("onSongStart")
end

function PlayScreen:endSong()
    if self.endingSong then
        return
    end
    self:switchTo(srcreq("funkin.screens.freeplayscreen"):new())

    if self.scripts then
        self.scripts:call("onEndSong")
        self.scripts:call("onSongEnd")
    end
end

function PlayScreen:beatHit(beat)
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor

    local zoomInterval = self.camZoomingInterval >= 0 and self.camZoomingInterval or c:getCurrentTimeSignature()[1]
    local beatOffset = self.camZoomingOffset >= 0 and beat + self.camZoomingOffset or math.floor(beat - c._latestTimingPoint.beat)

    if beat > 0 and beatOffset % zoomInterval == 0 then
        self.camGame.zoom:set(self.camGame.zoom.x + 0.015, self.camGame.zoom.y + 0.015)
        self.camHUD.zoom:set(self.camHUD.zoom.x + 0.03, self.camHUD.zoom.y + 0.03)
    end
    self.scripts:call("onBeatHit", beat)
end

function PlayScreen:stepHit(step)
    self.scripts:call("onStepHit", step)
end

function PlayScreen:measureHit(measure)
    self.scripts:call("onMeasureHit", measure)
end

function PlayScreen:exit()
    local tracks = self.vocalTracks
    for i = 1, #tracks do
        tracks[i]:destroy()
    end
    self.vocalTracks = nil

    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    c.offset = 0
    
    self.scripts:close()
    self.scripts = nil

    PlayScreen.static.instance = nil
end

return PlayScreen