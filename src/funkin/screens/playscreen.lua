local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin
local StrumLine = srcreq("funkin.gameplay.notes.strumline") --- @type funkin.gameplay.notes.StrumLine

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
    comet.mixer.music:stop()
    comet.mixer.music:setSource(Paths.inst(self.currentSong, self.currentMix, self.parentContentPack))
    comet.mixer.music:setLooping(false)
    comet.mixer.music:setVolume(1.0)

    self.inst = comet.mixer.music
    self.inst.onComplete:connect(function()
        self:endSong()
    end)
    self.currentChart = {}
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
        track:play()
        table.insert(self.vocalTracks, track)
    end
    self.inst:setPitch(1)
    self.inst:seek(0)
    self.inst:play()

    Conductor.instance.music = self.inst

    self.opponentStrums = StrumLine:new(comet.getDesiredWidth() * 0.25, 100) --- @type funkin.gameplay.notes.StrumLine
    self:addChild(self.opponentStrums)

    self.playerStrums = StrumLine:new(comet.getDesiredWidth() * 0.75, 100) --- @type funkin.gameplay.notes.StrumLine
    self:addChild(self.playerStrums)
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