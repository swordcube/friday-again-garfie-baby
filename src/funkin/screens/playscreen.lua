local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin
local StrumLine = srcreq("funkin.gameplay.notes.strumline") --- @type funkin.gameplay.notes.StrumLine
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

    NoteSkin.clearCache()

    local tracks = {
        Paths.vocalTrack(self.currentSong, self.currentMix, "vocals-" .. self.currentChart.meta.playData.characters.opponent, self.parentContentPack),
        Paths.vocalTrack(self.currentSong, self.currentMix, "vocals-" .. self.currentChart.meta.playData.characters.player, self.parentContentPack)
    }
    self.vocalTracks = {}

    for i = 1, #tracks do
        local track = comet.mixer:load(tracks[i])
        track:setPitch(1)
        track:seek(0)
        table.insert(self.vocalTracks, track)
    end
    self.inst:setPitch(1)
    self.inst:seek(0)

    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    c.music = nil
    c:setCurrentRawTime(c:getCurrentBeatLength() * -5)

    self.playField = PlayField:new() --- @type funkin.gameplay.PlayField
    self.playField:prepareChart(self.currentChart, self.currentDifficulty)
    self:addChild(self.playField)
end

function PlayScreen:update(dt)
    local c = Conductor.instance --- @type funkin.backend.plugins.Conductor
    if self.startingSong and c:getCurrentRawTime() >= 0.0 then
        self:startSong()
    end
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

function PlayScreen:exit()
    local tracks = self.vocalTracks
    for i = 1, #tracks do
        tracks[i]:destroy()
    end
    self.vocalTracks = {}
    
    PlayScreen.static.instance = nil
end

return PlayScreen