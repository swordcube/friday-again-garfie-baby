--- @class funkin.gfx.AnimatedVelocityImage : comet.gfx.AnimatedImage
local AnimatedVelocityImage, super = AnimatedImage:subclass("AnimatedVelocityImage", ...)

function AnimatedVelocityImage:__init__(x, y)
    super.__init__(self, x, y)

    self.acceleration = Vec2:new()
    self.velocity = Vec2:new()

    self.moving = true
end

local function computeVelocity(vel, accel, dt)
    return vel + (accel * dt)
end

local function computeVelocityDelta(vel, accel, dt)
    local x = 0.5 * (computeVelocity(vel.x, accel.x, dt) - vel.x)
    local y = 0.5 * (computeVelocity(vel.y, accel.y, dt) - vel.y)
    return x, y
end

function AnimatedVelocityImage:update(dt)
    super.update(self, dt)
    if not self.moving then
        return
    end
    local dx, dy = computeVelocityDelta(self.velocity, self.acceleration, dt)
    self.position.x = self.position.x + ((self.velocity.x + dx) * dt)
    self.position.y = self.position.y + ((self.velocity.y + dy) * dt)

    self.velocity.x = self.velocity.x + (dx * 2.0)
    self.velocity.y = self.velocity.y + (dy * 2.0)
end

return AnimatedVelocityImage