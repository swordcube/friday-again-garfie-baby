function onLoadPost()
    woman = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
    woman:setFrameCollection(Paths.getSparrowAtlas("game/characters/gf/woman"))
    woman:addAnimationByIndices("danceLeft", "GF Dancing Beat", table.numberList(1, 15), 24, false)
    woman:addAnimationByIndices("danceRight", "GF Dancing Beat", table.numberList(16, 30), 24, false)
    woman:playAnimation("danceLeft")
    woman.position:set(getWidth() * 0.5, -90)
    addChild(woman)

    danceRight = true
end

function onUpdate(dt)
    if woman:getShader() ~= getShader() then
        woman:setShader(getShader())
    end
end

function onDance()
    if not woman then
        return
    end
    danceRight = not danceRight
    if danceRight then
        woman:playAnimation("danceRight")
    else
        woman:playAnimation("danceLeft")
    end
end