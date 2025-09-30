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
    comet.mixer.music:play()
end

function PlayScreen:exit()
    PlayScreen.static.instance = nil
end

return PlayScreen