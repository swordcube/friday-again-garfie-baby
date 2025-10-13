local motionShader = Shader:new(Paths.frag("motion_blur")) --- @type comet.gfx.Shader
local motionShaderForHud = Shader:new(Paths.frag("motion_blur")) --- @type comet.gfx.Shader
local game = nil

function onEnterPost()
    game = PlayScreen.instance

    game.camGame:setShaders({motionShader})
    motionShader:send("Intensity", 0.2)
    motionShader:send("Direction", {0, 0});

    local theNotes = game.playField.notes;
    game.playField:removeChild(theNotes);
    game.camOther:addChild(theNotes);
    game.camOther:setShaders({motionShaderForHud})
    motionShaderForHud:send("Intensity", 0.03)
    motionShaderForHud:send("Direction", {0, 1});
end

local cameraPastX = 0
local cameraPastY = 0
local intensitylerp = 0
function onUpdate(dt)
    motionShader:send("iTime", Conductor.instance:getCurrentRawTime())
    intensitylerp = math.lerp(intensitylerp, math.abs((game.camGame._scrollTarget.x - cameraPastX) / 700), 1.0 - math.pow(1.0 - 0.5, dt * 60));
    motionShader:send("Intensity", intensitylerp)
    motionShader:send("Direction", {math.max(game.camGame._scrollTarget.x-cameraPastX, 0.000001), math.max(game.camGame._scrollTarget.y-cameraPastY, 0.000001)});
    cameraPastX = game.camGame._scrollTarget.x
    cameraPastY = game.camGame._scrollTarget.y
end