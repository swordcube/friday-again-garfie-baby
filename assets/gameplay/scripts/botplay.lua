function onUpdate(dt)
    if FlxG.keys.justPressed.F6 then
        playField.playerStrumLine.botplay = not playField.playerStrumLine.botplay
        playField.hud.updatePlayerStats(playField.stats)
    end
end