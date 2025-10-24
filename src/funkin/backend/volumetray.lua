--- @class funkin.backend.VolumeTray
local VolumeTray = {}

local gfx = love.graphics

function VolumeTray.init()
    VolumeTray.gfxScale = 0.6
    VolumeTray.scaleX, VolumeTray.scaleY = 1, 1

    VolumeTray.squishTimer = math.huge
    VolumeTray.shakeMult = 0.0

    VolumeTray.images = {
        box = gfx.newImage(Paths.image("ui/volume/images/volumebox")),
        bars = {
            gfx.newImage(Paths.image("ui/volume/images/bars_1")),
            gfx.newImage(Paths.image("ui/volume/images/bars_2")),
            gfx.newImage(Paths.image("ui/volume/images/bars_3")),
            gfx.newImage(Paths.image("ui/volume/images/bars_4")),
            gfx.newImage(Paths.image("ui/volume/images/bars_5")),
            gfx.newImage(Paths.image("ui/volume/images/bars_6")),
            gfx.newImage(Paths.image("ui/volume/images/bars_7")),
            gfx.newImage(Paths.image("ui/volume/images/bars_8")),
            gfx.newImage(Paths.image("ui/volume/images/bars_9")),
            gfx.newImage(Paths.image("ui/volume/images/bars_10")),
        }
    }
    VolumeTray.y = -88
    VolumeTray.alpha = 0

    VolumeTray.targetY = -88
    VolumeTray.targetAlpha = 0

    VolumeTray.timer = 0.0
    VolumeTray.saved = false
    
    VolumeTray.sfx = {
        up = comet.mixer:getSource(Paths.sound("ui/volume/sfx/up")), --- @type comet.mixer.Source
        down = comet.mixer:getSource(Paths.sound("ui/volume/sfx/down")), --- @type comet.mixer.Source
        max = comet.mixer:getSource(Paths.sound("ui/volume/sfx/max")) --- @type comet.mixer.Source
    }
    for _, sfx in pairs(VolumeTray.sfx) do
        sfx:reference()
    end
    comet.signals.postInput:connect(VolumeTray.postInput)
    comet.signals.postUpdate:connect(VolumeTray.postUpdate)
    comet.signals.postDraw:connect(VolumeTray.postDraw)
end

function VolumeTray.changeVolume(by)
    comet.mixer:setMasterVolume(math.clamp(comet.mixer:getMasterVolume() + by, 0.0, 1.0))
    VolumeTray.show(by > 0)
end

function VolumeTray.show(up)
    local volumeChunks = math.round(comet.mixer:getMasterVolume() * 10)
    Timer.wait(0, function(_)
        if up then
            comet.mixer:play(volumeChunks >= 10 and VolumeTray.sfx.max or VolumeTray.sfx.up)
        else
            comet.mixer:play(VolumeTray.sfx.down)
        end
    end)
    VolumeTray.scaleX = 1.035
    VolumeTray.scaleY = 0.965

    VolumeTray.targetY = 10
    VolumeTray.targetAlpha = 1.0

    VolumeTray.timer = 1.0
    VolumeTray.squishTimer = 1 / 18

    VolumeTray.saved = false

    if volumeChunks >= 10 then
        VolumeTray.shakeMult = 1.0
    end
end

function VolumeTray.postInput(e)
    if e.type == "text" then
        return
    end
    if Controls.instance.justPressed.VOLUME_UP then
        VolumeTray.changeVolume(0.1)
    end
    if Controls.instance.justPressed.VOLUME_DOWN then
        VolumeTray.changeVolume(-0.1)
    end
    if Controls.instance.justPressed.VOLUME_MUTE then
        if comet.mixer:isMasterMuted() then
            comet.mixer:unmuteMaster()
        else
            comet.mixer:muteMaster()
        end
        VolumeTray.show(true)
    end
end

function VolumeTray.postUpdate()
    local dt = comet.getRawDeltaTime()
    VolumeTray.squishTimer = VolumeTray.squishTimer - dt

    if VolumeTray.squishTimer <= 0.0 then
        VolumeTray.scaleX, VolumeTray.scaleY = 1.0, 1.0
        VolumeTray.squishTimer = math.huge
    end
    VolumeTray.y = math.max(math.lerp(VolumeTray.y, VolumeTray.targetY, dt * 6.0), -88)

    if math.floor(VolumeTray.y) <= -88 and not VolumeTray.saved then
        VolumeTray.saved = true
        FLog.verbose(("Saving volume as %d%s (muted: %s)"):format(math.round(comet.mixer:getMasterVolume() * 100), "%", comet.mixer:isMasterMuted() and "yes" or "no"))

        Options.masterVolume = comet.mixer:getMasterVolume()
        Options.masterMuted = comet.mixer:isMasterMuted()
        Options.save()
    end
    VolumeTray.alpha = math.clamp(math.lerp(VolumeTray.alpha, VolumeTray.targetAlpha, dt * 15.0), 0.0, 1.0)
    VolumeTray.shakeMult = math.max(VolumeTray.shakeMult - (dt * 3.0), 0.0)

    if VolumeTray.timer > 0.0 and not comet.mixer:isMasterMuted() then
        VolumeTray.timer = VolumeTray.timer - dt
        if VolumeTray.timer <= 0.0 then
            VolumeTray.targetY = -88
            VolumeTray.targetAlpha = 0
        end
    end
end

function VolumeTray.postDraw()
    if VolumeTray.alpha < 0.05 then
        return
    end
    local imgs = VolumeTray.images
    local volumeX, volumeY = ((gfx.getWidth() - (imgs.box:getWidth() * VolumeTray.gfxScale * VolumeTray.scaleX)) * 0.5) + (love.math.random(-2, 2) * VolumeTray.shakeMult), VolumeTray.y + (love.math.random(-2, 2) * VolumeTray.shakeMult)
    
    gfx.setColor(1, 1, 1, VolumeTray.alpha)
    gfx.draw(imgs.box, volumeX, volumeY, 0, VolumeTray.gfxScale * VolumeTray.scaleX, VolumeTray.gfxScale * VolumeTray.scaleY)

    gfx.setColor(1, 1, 1, 0.4 * VolumeTray.alpha)
    gfx.draw(imgs.bars[10], volumeX + (30 * VolumeTray.gfxScale * VolumeTray.scaleX), volumeY + (18 * VolumeTray.gfxScale * VolumeTray.scaleY), 0, VolumeTray.gfxScale * VolumeTray.scaleX, VolumeTray.gfxScale * VolumeTray.scaleY)

    gfx.setColor(1, 1, 1, VolumeTray.alpha)
    local volumeChunks = math.round(comet.mixer:getMasterVolume() * 10) * (comet.mixer:isMasterMuted() and 0.0 or 1.0)
    if volumeChunks > 0 then
        gfx.draw(imgs.bars[volumeChunks], volumeX + (30 * VolumeTray.gfxScale * VolumeTray.scaleX), volumeY + (18 * VolumeTray.gfxScale * VolumeTray.scaleY), 0, VolumeTray.gfxScale * VolumeTray.scaleX, VolumeTray.gfxScale * VolumeTray.scaleY)
    end
    gfx.setColor(1, 1, 1, 1)
end

function VolumeTray.destroy()
    comet.signals.postInput:disconnect(VolumeTray.postInput)
    comet.signals.postUpdate:disconnect(VolumeTray.postUpdate)
    comet.signals.postDraw:disconnect(VolumeTray.postDraw)
end

return VolumeTray