local CharacterConfig = srcreq("funkin.gameplay.character.config") --- @type funkin.gameplay.character.Config

--- @class funkin.gameplay.Character : comet.gfx.AnimatedImage
local Character, super = AnimatedImage:subclass("Character", ...)

Character.static.FALLBACK_CHARACTER = "bf"

function Character:__init__(x, y, name, isPlayer)
    super.__init__(self, x, y)

    self.name = nil --- @type string
    self.isPlayer = isPlayer --- @type boolean

    self.curDanceStep = 1

    self.config = nil --- @type funkin.gameplay.character.Config.ConfigData
    self:loadCharacter(name)
end

function Character:loadCharacter(newCharacter)
    if self.name == newCharacter then
        return
    end
    self.name = newCharacter
    self.config = CharacterConfig.get(self.name)

    if not self.config.animations then
        self.name = Character.FALLBACK_CHARACTER
        self.config = CharacterConfig.get(self.name)
    end
    -- TODO: more atlas type support than just sparrow
    self:setFrameCollection(Paths.getSparrowAtlas(("game/characters/%s/%s"):format(self.name, self.config.atlas.path or "sprite")))

    local anims = self.config.animations
    for i = 1, #anims do
        local anim = anims[i]
        if anim.indices and #anim.indices ~= 0 then
            self:addAnimationByIndices(anim.shortcut or anim.name, anim.prefix or anim.name, anim.indices, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
        else
            self:addAnimationByName(anim.shortcut or anim.name, anim.prefix or anim.name, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
        end
        self:setAnimationOffset(anim.shortcut or anim.name, anim.offset[1] or 0.0, anim.offset[2] or 0.0)
    end
    self.scale:set(
        self.config.scale and self.config.scale or 1.0,
        self.config.scale and self.config.scale or 1.0
    )
    if self.config.centered ~= nil then
        self.centered = self.config.centered
    else
        self.centered = true
    end
    if self.config.flipX ~= nil then
        self.flipX = self.config.flipX
    else
        self.flipX = false
    end
    if self.config.flipY ~= nil then
        self.flipY = self.config.flipY
    else
        self.flipY = false
    end
    if self.config.antialiasing ~= nil then
        self.antialiasing = self.config.antialiasing
    else
        self.antialiasing = true
    end
    self.danceInterval = self.config.danceInterval or 2
    self.singDuration = self.config.singDuration or 4.0
    self:dance()
end

function Character:dance(force)
    self:playAnimation(self.config.danceSteps[self.curDanceStep], force)
end

function Character:playAnimation(name, force)
    super.playAnimation(self, name, force)
    if self.centered then
        self.offset.x = 0.0
        self.offset.y = self:getHeight(1) * -0.5
    else
        self.offset.x = self:getWidth(1) * -0.5
        self.offset.y = -self:getHeight(1)
    end
    self.offset.x = self.offset.x + (self.config.offset and self.config.position[1] or 0.0)
    self.offset.y = self.offset.y + (self.config.offset and self.config.position[2] or 0.0)
end

function Character:draw()
    if self.isPlayer then
        self.flipX = not self.flipX
    end
    super.draw(self)
    if self.isPlayer then
        self.flipX = not self.flipX
    end
end

function Character:beatHit(beat)
    if not table.contains(self.config.singSteps, self:getCurrentAnimation()) and beat % self.danceInterval == 0 then
        self:dance()
    end
end

return Character