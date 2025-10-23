local fs = love.filesystem
local json = cometreq("lib.json") --- @type comet.lib.Json

local CharacterConfig = srcreq("funkin.gameplay.character.config") --- @type funkin.gameplay.character.Config

--- @class funkin.gameplay.Character : comet.gfx.AnimatedImage
local Character, super = AnimatedImage:subclass("Character", ...)

Character.static.FALLBACK_CHARACTER = "bf"

function Character:__init__(x, y, name, isPlayer)
    super.__init__(self, x, y)

    self.name = nil --- @type string
    self.isPlayer = isPlayer --- @type boolean

    self.curDanceStep = 1
    self.debugMode = false

    self.holdTimer = 0.0
    self.curAnimContext = "dance" --- @type "none"|"dance"|"sing"|"lock"
    
    self.script = nil --- @type funkin.scripting.Script
    self.midpoint = Vec2:new() --- @type comet.math.Vec2

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
    if self.script then
        self.script:close()
        self.script = nil
    end
    local scriptPath = Paths.script(("game/characters/%s/script"):format(self.name))
    if fs.isFile(scriptPath) then
        self.script = Script:new(scriptPath) --- @type funkin.scripting.Script
    end
    if self.script then
        self.script:linkObject(self)
        self.script:call("onLoad")
    end
    -- TODO: more atlas type support than just sparrow
    self:setFrameCollection(Paths.getSparrowAtlas(("game/characters/%s/%s"):format(self.name, self.config.atlas.path or "sprite")))

    local anims = self.config.animations
    for i = 1, #anims do
        local anim = anims[i]
        if anim.indices and anim.indices ~= json.null and #anim.indices ~= 0 then
            self.animation:addByIndices(anim.shortcut or anim.name, anim.prefix or anim.name, anim.indices, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
        else
            self.animation:addByName(anim.shortcut or anim.name, anim.prefix or anim.name, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
        end
        self.animation:setOffset(anim.shortcut or anim.name, anim.offset[1] or 0.0, anim.offset[2] or 0.0)
    end
    local localIsPlayer = self.config.isPlayer
    if localIsPlayer == nil then
        localIsPlayer = false
    end
    if self.isPlayer ~= localIsPlayer then
        -- swap left & right sing anims if player-intended character is used on non-player character instance
        local old = self.animation._animations[self.config.singSteps[1]]
        self.animation._animations[self.config.singSteps[1]] = self.animation._animations[self.config.singSteps[4]]
        self.animation._animations[self.config.singSteps[4]] = old
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
    self.midpoint:set(self:getWidth(1) * 0.5, self:getHeight(1) * 0.5)

    if self.script then
        self.script:call("onLoadPost")
    end
end

function Character:dance(force)
    if self.script then
        self.script:call("onDance")
    end
    self:playAnimation(self.config.danceSteps[self.curDanceStep], "dance", force)
    self.curDanceStep = (self.curDanceStep % #self.config.danceSteps) + 1
    
    if self.script then
        self.script:call("onDancePost")
    end
end

function Character:playSingAnimation(dir)
    self:playAnimation(self.config.singSteps[(dir % #self.config.singSteps) + 1], "sing", true)
end

function Character:playMissAnimation(dir)
    self:playAnimation(self.config.missSteps[(dir % #self.config.missSteps) + 1], "sing", true)
end

---@param name string
---@param context "none"|"dance"|"sing"|"lock"
---@param force any
function Character:playAnimation(name, context, force)
    local lastAnimContext = self.curAnimContext
    if context == "dance" then
        if lastAnimContext == "none" and not self.animation:isFinished() then
            return
        end
    elseif context == "sing" then
        if lastAnimContext == "none" and not self.animation:isFinished() then
            return
        end
        self.holdTimer = Conductor.instance:getCurrentStepLength() * self.singDuration
    end
    self.curAnimContext = context
    super.playAnimation(self, name, force)

    local posX, posY = self.config.position and self.config.position[1] or 0.0, self.config.position and self.config.position[2] or 0.0
    if self.centered then
        self.offset.x = posX
        self.offset.y = posY + (self:getHeight(1) * -0.5)
    else
        self.offset.x = posX + (self:getWidth(1) * -0.5)
        self.offset.y = posY - self:getHeight(1)
    end
    self.offset.x = self.offset.x + (self.config.offset and self.config.position[1] or 0.0)
    self.offset.y = self.offset.y + (self.config.offset and self.config.position[2] or 0.0)

    if self.script then
        self.script:call("onPlayAnimation", name, context, force)
    end
end

local defaultCamOffset = {0, 0}
function Character:getCameraPosition()
    local camera = self.config.camera or defaultCamOffset
    local offset = self.config.offset or defaultCamOffset -- default offset should be 0,0 so we can reuse defaultCamOffset here

    local x, y = self.position.x + offset[1], self.position.y - self.midpoint.y + offset[2]
    x = x + (camera[1] + (self.isPlayer and -100 or 150))
    y = y + (camera[2] - 100)
    return x, y
end

function Character:update(dt)
    if self.script then
        self.script:call("onUpdate", dt)
    end
    super.update(self, dt)

    -- dance is handled by beatHit
    -- "none" waits until the current anim is done playing to start automatically dancing again
    -- "sing" waits until the hold timer reaches 0 (and if player, all note inputs to be released) to start automatically dancing again

    -- "lock" prevents the character from dancing automatically until dance() is called again
    -- lock doesn't need to do anything, so there's no code for it lol

    if self.curAnimContext == "sing" then
        local holdingAnyNoteInput = Controls.instance.pressed.NOTE_LEFT or Controls.instance.pressed.NOTE_DOWN or Controls.instance.pressed.NOTE_UP or Controls.instance.pressed.NOTE_RIGHT
        self.holdTimer = self.holdTimer - (dt * 1000.0)

        if self.holdTimer <= 0.0 and (not self.isPlayer or (self.isPlayer and not holdingAnyNoteInput)) then
            self.curDanceStep = 1
            self:dance()
        end
    elseif self.curAnimContext == "none" and not self.animation:isPlaying() then
        self:dance()
    end
    if self.script then
        self.script:call("onUpdatePost", dt)
    end
end

function Character:draw()
    if self.script then
        self.script:call("onDraw")
    end
    if self.isPlayer then
        self.flipX = not self.flipX
    end
    super.draw(self)
    if self.isPlayer then
        self.flipX = not self.flipX
    end
    if self.script then
        self.script:call("onDrawPost")
    end
end

function Character:beatHit(beat)
    if not self.debugMode and self.curAnimContext == "dance" and beat % self.danceInterval == 0 then
        self:dance()
    end
    if self.script then
        self.script:call("onBeatHit", beat)
    end
end

function Character:stepHit(step)
    if self.script then
        self.script:call("onStepHit", step)
    end
end

function Character:measureHit(note)
    if self.script then
        self.script:call("onMeasureHit", note)
    end
end

return Character