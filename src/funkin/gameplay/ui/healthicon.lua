local CharacterConfig = srcreq("funkin.gameplay.character.config") --- @type funkin.gameplay.character.Config

--- @class funkin.gameplay.ui.HealthIcon : comet.gfx.AnimatedImage
local HealthIcon, super = AnimatedImage:subclass("HealthIcon", ...)

function HealthIcon:__init__(character, isPlayer)
    super.__init__(self)

    self.character = nil --- @type string
    self.config = nil

    self.isPlayer = isPlayer --- @type boolean

    --- @type number
    self._health = 0.5 --- @protected

    self.flipX = isPlayer
    self:loadCharacter(character)
end

--- @param character string
function HealthIcon:loadCharacter(character)
    if self.character == character then
        return
    end
    self.config = CharacterConfig.get(character).healthIcon or {
        isPixel = false,
        scale = 1,
        offset = {0, 0},
        color = "#FFFFFF"
    }
    self.character = character
    self.antialiasing = not self.config.isPixel and (self.config.antialiasing ~= nil and self.config.antialiasing or true) or false

    local gridSize = self.config.isPixel and 32 or 150
    self:setFrameCollection(FrameCollection.fromTexture(Paths.image(("game/icons/%s"):format(character)), gridSize, gridSize))

    self:addAnimation("idle", {1}, 0, true)
    self:addAnimation("losing", {2}, 0, true)

    if self:getFrameCollection():getFrameCount("grid") > 2 then
        self:addAnimation("winning", {3}, 0, true)
    end
    self:playAnimation("idle")
end

function HealthIcon:getHealth()
    return self._health
end

function HealthIcon:setHealth(newHealth)
    if self._health == newHealth then
        return
    end
    newHealth = math.clamp(newHealth, 0.0, 1.0)
    self._health = newHealth

    -- TODO: add support for transitional animations between states
    if newHealth <= 0.2 and self:hasAnimation("losing") then
        self:playAnimation("losing")
    elseif newHealth >= 0.8 and self:hasAnimation("winning") then
        self:playAnimation("winning")
    else
        self:playAnimation("idle")
    end
end

return HealthIcon