--- @class funkin.screens.OptionsScreen : funkin.screens.MusicBeatScreen
local OptionsScreen = MusicBeatScreen:extend("OptionsScreen", ...)

function OptionsScreen:enter()
    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic()
    end
end

return OptionsScreen