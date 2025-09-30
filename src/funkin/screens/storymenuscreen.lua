--- @class funkin.screens.StoryMenuScreen : funkin.screens.MusicBeatScreen
local StoryMenuScreen = MusicBeatScreen:subclass("StoryMenuScreen", ...)

function StoryMenuScreen:enter()
    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic()
    end
end

return StoryMenuScreen