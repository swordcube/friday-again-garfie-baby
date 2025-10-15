local colorShader = nil --- @type comet.gfx.Shader

-- TODO: the cars lmao

function onLoad()
    colorShader = Shader:new(Paths.frag("adjust_color")) --- @type comet.gfx.Shader
    colorShader:send("hue", -5)
    colorShader:send("saturation", -40)
    colorShader:send("contrast", -25)
    colorShader:send("brightness", -20)
end

function onLoadPost()
    local layer1 = Parallax2D:new() --- @type comet.gfx.Parallax2D
    layer1.scrollFactor:set(0.1, 0.1)
    insertChild(1, layer1)

    -- extra props
    local scrollingSky = Backdrop:new(getStageImage("philly-streets-erect/images/phillySkybox"), "x") --- @type comet.gfx.Backdrop
    scrollingSky.position:set(-650, -375)
    scrollingSky.scale:set(0.65, 0.65)
    scrollingSky.position:set(
        scrollingSky.position.x + (scrollingSky:getOriginalWidth() - scrollingSky:getWidth()),
        scrollingSky.position.y + (scrollingSky:getOriginalHeight() - scrollingSky:getHeight())
    )
    scrollingSky.velocity.x = -22
    scrollingSky.centered = false -- just to better match flixel positioning
    layer1:addChild(scrollingSky)

    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistMid"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 0.6
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = 172
    addProp("mist0", mist, {1.2, 1.2})

    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistMid"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 0.6
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = 150
    addProp("mist1", mist, {1.1, 1.1})

    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistBack"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 0.8
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = 150
    addProp("mist2", mist, {1.2, 1.2})

    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistMid"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 0.5
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = -50
    mist.scale:set(0.8, 0.8)
    mist.position:set(
        mist.position.x + (mist:getOriginalWidth() - mist:getWidth()),
        mist.position.y + (mist:getOriginalHeight() - mist:getHeight())
    )
    insertProp("mist3", mist, {0.95, 0.95}, 7)
    
    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistMid"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 1
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = 40
    mist.scale:set(0.7, 0.7)
    mist.position:set(
        mist.position.x + (mist:getOriginalWidth() - mist:getWidth()),
        mist.position.y + (mist:getOriginalHeight() - mist:getHeight())
    )
    insertProp("mist4", mist, {0.8, 0.8}, 6)

    local mist = Backdrop:new(getStageImage("philly-streets-erect/images/mistMid"), "x") --- @type comet.gfx.Backdrop
    mist.position:set(-650, -100)
    mist.blend = "add"
    mist.alpha = 1
    mist.centered = false -- just to better match flixel positioning
    mist:setTint(0xFF5c5c5c)
    mist.velocity.x = 20
    mist.scale:set(1.1, 1.1)
    mist.position:set(
        mist.position.x + (mist:getOriginalWidth() - mist:getWidth()),
        mist.position.y + (mist:getOriginalHeight() - mist:getHeight())
    )
    insertProp("mist5", mist, {0.5, 0.5}, 2)

    -- apply goofy blend mode shit
    for name, prop in pairs(props) do
        if name:endsWith("_lightmap") then
            prop.blend = "add"
            prop.alpha = 0.6
        end
    end
    props.grey1.blend = "add"
    -- props.grey2.blend = "multiply" -- this appears to darken most of the stage??

    props.paper.onComplete:connect(function(_)
        props.paper:kill()
    end)
    props.paper:pause()
    props.paper:kill()

    local chars = {
        props.opponent,
        props.player,
        props.spectator
    }
    local fadeShader = Shader:new(Paths.frag("gradient_fade"))
    fadeShader:reference()

    for i, char in ipairs(chars) do
        -- i probably should aim the reflections more towards the road
        -- but comet transforms don't have shear/skewing, so i can't
        -- and i'm tired and lazy so fuck you
        char.onDraw = function(spr)
            local prevAlpha, prevShader = spr.alpha, spr:getShader()
            spr.alpha = prevAlpha * 0.25
            spr.flipY = not spr.flipY

            fadeShader:send("quad", {spr._frame.quad:getViewport()})
            spr:setShader(fadeShader)

            local woman = props.spectator.script:get("woman")
            woman.visible = not woman.visible

            spr.position.y = spr.position.y + ((spr:getHeight(1) * 0.98) + spr.reflectionOffY)
            spr:_draw()
            
            spr.alpha = prevAlpha
            spr.flipY = not spr.flipY
            spr:setShader(prevShader)
            spr.position.y = spr.position.y - ((spr:getHeight(1) * 0.98) + spr.reflectionOffY)
            
            woman.visible = not woman.visible
            spr:_draw()
        end
        local d = char.destroy
        char.destroy = function(c)
            fadeShader:dereference()
            d(c)
        end
        char.reflectionOffY = 0
    end
    props.opponent.reflectionOffY = 60

    rainShader = Shader:new(Paths.frag("rain")) --- @type comet.gfx.Shader
    rainShader:send("distortionStrength", 0.5)
    rainShader:send("scale", comet.getDesiredHeight() / 200)

    rainStartIntensity, rainEndIntensity = 0, 0
    if game.currentSong == "darnell-bf-mix" then
        rainStartIntensity = 0
        rainEndIntensity = 0.1
    elseif game.currentSong == "lit-up-bf-mix" then
        rainStartIntensity = 0.1
        rainEndIntensity = 0.2
    elseif game.currentSong == "2hot" then
        rainStartIntensity = 0.2
        rainEndIntensity = 0.4
    end
    rainShader:send("intensity", rainStartIntensity)
    rainShader:send("time", 0)

    local hue = Shader:new(Paths.frag("hue_offset")) --- @type comet.gfx.Shader
    game.camGame:setShaders({rainShader, hue})
end

function onCharacterAdd(char)
    char:setShader(colorShader)
end

local timer = 0

function onUpdate(dt)
    timer = timer + dt
    props.mist0.position.y = 660 + (math.fastsin(timer * 0.35) * 70)
    props.mist1.position.y = 500 + (math.fastsin(timer * 0.3) * 80)
    props.mist2.position.y = 540 + (math.fastsin(timer * 0.4) * 60)
    props.mist3.position.y = 230 + (math.fastsin(timer * 0.3) * 70)
    props.mist4.position.y = 170 + (math.fastsin(timer * 0.35) * 50)
    props.mist5.position.y = -80 + (math.fastsin(timer * 0.08) * 100)

    local intensityValue = 0.0
    if comet.mixer.music:isPlaying() then
        intensityValue = math.remapToRange(
            Conductor.instance:getCurrentTime(), 0, comet.mixer.music:getDuration(),
            rainStartIntensity, rainEndIntensity
        )
    else
        intensityValue = rainStartIntensity
    end
    rainShader:send("intensity", intensityValue)
    rainShader:send("time", rainShader:getUniformNumber("time") + dt)
end

local paperOffset = math.floor(love.math.random(20, 40))

function onBeatHit(b)
    if b >= paperOffset and love.math.chance(1) and not props.paper:isPlaying() then
        paperOffset = b + math.floor(love.math.random(20, 40))

        props.paper.position.y = 608 + math.random(-150, 150)
        props.paper:playAnimation("idle", true)

        props.paper:revive()
    end
end