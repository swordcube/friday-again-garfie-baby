local gfx = love.graphics

--- @class funkin.gfx.Video : comet.gfx.Image
--- A basic object for displaying video.
local Video, super = Image:extend("Video", ...)

function Video:__init__(filePath, settings)
    super.__init__(self)
    self:loadTexture(nil)

    self.video = love.graphics.newVideo(filePath, settings)
    self.texture = self.video -- too lazy to edit most of the functions so fuck it we ball
end

function Video:tell()
    return self.video:tell()
end

function Video:getDuration()
    return self.video.getDuration and self.video:getDuration() or 0.0
end

function Video:seek(time)
    self.video:seek(time)
end

function Video:play()
    self.video:play()
end

function Video:pause()
    self.video:pause()
end

function Video:stop()
    self.video:stop()
end

function Video:getVolume()
    return self.video:getSource():getVolume()
end

function Video:setVolume(vol)
    self.video:getSource():setVolume(vol)
end

function Video:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local transform = self:getTransform()
    local box = self:getBoundingBox(transform, self._rect)
    if not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    gfx.setBlendMode("alpha", "alphamultiply")
    gfx.setColor(self._tint.r, self._tint.g, self._tint.b, self._tint.a * self.alpha)

    if self.shader then
        gfx.setShader(self.shader)
    else
        gfx.setShader(comet._defaultShader)
    end
    local img = self.video.image --- @type love.Image
    if img then
        local filter = self.antialiasing and "linear" or "nearest"
        img:setFilter(filter, filter)
    end
    gfx.draw(self.video, transform:getRenderValues())
    gfx.setColor(pr, pg, pb, pa)

    if comet.settings.debugDraw then
        gfx.setLineWidth(4)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
end

function Video:destroy()
    self.texture = nil
    if self.video then
        self.video:release()
        self.video = nil
    end
    super.destroy(self)
end

return Video