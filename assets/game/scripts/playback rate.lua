local funny = false
local speedText = nil

function onEnterPost()
    speedText = Label:new() --- @type comet.gfx.Label
    speedText:setFont(Paths.font("fonts/vcr"))
    speedText:setSize(16)
    speedText:setColor(Color.WHITE)
    speedText:setBorderColor(Color.BLACK)
    speedText.borderSize = 1
    speedText.centered = false
    camOther:addChild(speedText)

    setThatShit(1.0)
end

function setThatShit(new)
    setPlaybackRate(new)
    speedText.text = "Rate: " .. string.format("%.2f", new)
    speedText.position:set(comet.getDesiredWidth() - (speedText:getWidth() + 4), comet.getDesiredHeight() - (speedText:getHeight() + 2  ))
end

function onUpdate(dt)
    if comet.keys:wasJustPressed("`") then
        funny = not funny
    end
    if comet.keys:wasJustPressed("home") then
        setThatShit(1)
    end
    if comet.keys:wasJustPressed("pageup") then
        local amount = (comet.keys:isPressed("lshift") or comet.keys:isPressed("rshift")) and 0.25 or 0.01
        setThatShit(getPlaybackRate() + amount)
    end
    if comet.keys:wasJustPressed("pagedown") then
        local amount = (comet.keys:isPressed("lshift") or comet.keys:isPressed("rshift")) and 0.25 or 0.01
        setThatShit(getPlaybackRate() - amount)
    end
    if funny then
        setThatShit(math.abs(math.sin(Conductor.instance.curDecStep) * 0.25) + 0.75)
    end
end