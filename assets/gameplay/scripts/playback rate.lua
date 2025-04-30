local sex = false
local rateText = nil

function setRate(r)
    game.playbackRate = r

    rateText.text = "Rate: " .. FlxMath.roundDecimal(game.playbackRate, 2)
    rateText.setPosition(FlxG.width - rateText.width - 15, FlxG.height - rateText.height - 15)
end

function onCreatePost()
    rateText = FlxText:new(0, 0, 0, "3")
    rateText:setFormat(Paths.font("fonts/vcr"), 16)
    rateText:setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1)
    playField.hud.add(rateText)

    setRate(game.playbackRate)
end

-- function onPlayerHit(e)
--     if sex then
--         setRate(1)
--     end
-- end

function onUpdate(dt)
    if FlxG.keys.justPressed.GRAVEACCENT then
        sex = not sex
    end
    if FlxG.keys.justPressed.HOME then
        setRate(1)
    end
    if FlxG.keys.justPressed.PAGEUP then
        setRate(game.playbackRate + (FlxG.keys.pressed.SHIFT and 0.25 or 0.01))
    end
    if FlxG.keys.justPressed.PAGEDOWN then
        setRate(game.playbackRate - (FlxG.keys.pressed.SHIFT and 0.25 or 0.01))
    end
    if FlxG.keys.justPressed.F8 then
        setRate(10)
    end
    if sex then
        setRate(game.playbackRate - (dt * 0.25))
    end
end

function onClose()
    setRate(1)
end