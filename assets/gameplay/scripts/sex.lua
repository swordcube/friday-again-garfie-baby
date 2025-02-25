local sex = false
local rate = 1
local rateText = nil

function setRate(r)
    rate = r
    inst.pitch = rate
    
    if vocals.spectator then
        vocals.spectator.pitch = rate
    end
    if vocals.opponent then
        vocals.opponent.pitch = rate
    end
    if vocals.player then
        vocals.player.pitch = rate
    end

    rateText.text = "Rate: " .. FlxMath.roundDecimal(r, 2)
    rateText.setPosition(FlxG.width - rateText.width - 15, FlxG.height - rateText.height - 15)

    FlxG.timeScale = rate
end

function onCreatePost()
    rateText = FlxText:new(0, 0, 0, "3")
    rateText:setFormat(Paths.font("fonts/vcr"), 16)
    rateText:setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1)
    playField.hud.add(rateText)

    setRate(1)
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
        setRate(rate + (FlxG.keys.pressed.SHIFT and 0.25 or 0.01))
    end
    if FlxG.keys.justPressed.PAGEDOWN then
        setRate(rate - (FlxG.keys.pressed.SHIFT and 0.25 or 0.01))
    end
    -- if sex then
    --     setRate(rate - (dt * 0.25))
    -- end
end

function onStepHit()
    if sex then
        setRate(FlxG.random.float(0.5, 2.0)) 
    end
end

function onClose()
    setRate(1)
end