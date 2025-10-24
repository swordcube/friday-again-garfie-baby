local json = cometreq("lib.json") --- @type comet.lib.Json

local TiledAnimatedImage = cometreq("gfx.tiledanimatedimage") --- @type comet.gfx.TiledAnimatedImage
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.Sustain : comet.gfx.TiledAnimatedImage
local Sustain, super = Object2D:extend("Sustain", ...)

local sign, abs = math.sign, math.abs
local dirs = {"left", "down", "up", "right"}

function Sustain:__init__(x, y)
    super.__init__(self, x, y)

    self.note = nil --- @type funkin.gameplay.notes.Note

    self.skin = "funkin"
    self.skinData = nil
        
    self.line = TiledAnimatedImage:new() --- @type comet.gfx.TiledAnimatedImage
    self.line.horizontallyRepeat = false
    self.line.verticalPadding = 2
    self:addChild(self.line)

    self.tail = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
    self:addChild(self.tail)
    
    self.alpha = 1.0
    self.offsetX, self.offsetY = 0.0, 0.0
end

local function loadSkin(self, skin)
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    if not self.skinData.hold then
        self.skin = "funkin"
        self.skinData = NoteSkin.get("funkin")
    end
    -- TODO: more than just sparrow atlas!!

    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.hold.atlas.path)))
    for name, d in pairs(self.skinData.hold.animation) do
        for i = 1, #dirs do
            local dir = dirs[i]
            local animData = d[dir]
    
            if animData.indices and animData.indices ~= json.null and #animData.indices > 0 then
                self.animation:addByIndices(dir .. name, animData.prefix, animData.indices, animData.fps, animData.looped)
            else
                self.animation:addByName(dir .. name, animData.prefix, animData.fps, animData.looped)
            end
            self:setAnimationOffset(dir .. name, (animData and animData.offset) and animData.offset[1] or 0.0, (animData and animData.offset) and animData.offset[2] or 0.0)
        end
    end
    self.alpha = self.skinData.hold.alpha or 1.0
    self.scale:set(self.skinData.hold.scale, self.skinData.hold.scale)
    self.antialiasing = self.skinData.hold.antialiasing ~= nil and self.skinData.hold.antialiasing or true
end

--- @param note funkin.gameplay.notes.Note
function Sustain:setup(note)
    self.note = note
    
    loadSkin(self.line, note.skin)
    self.line:playAnimation(dirs[note.lane + 1] .. "hold", true)
    
    loadSkin(self.tail, note.skin)
    self.tail:playAnimation(dirs[note.lane + 1] .. "tail", true)

    self.offsetX, self.offsetY = 0.0, 0.0
end

function Sustain:updateVisuals()
    local strumLine = self.note.strumLine
    local speed = strumLine.scrollSpeed

    if strumLine.downscroll then
        speed = -speed
    end
    local note, speedSign, absSpeed = self.note, sign(speed), abs(speed)
    local sexo = (note.wasHit and not note.wasMissed) and math.max(Conductor.instance:getCurrentPlayhead() - note.time, 0.0) or 0.0
    self.line.verticalLength = ((0.45 * (note.length - sexo) * absSpeed) / self.line.scale.y) - self.tail:getHeight()

    if speedSign == 1 then
        -- upscroll
        self.line.position.y = self.line:getHeight() * 0.5
        self.line.flipY = true
        
        self.tail.position.y = self.line:getHeight() + (self.tail:getHeight() * 0.5)
        self.tail.flipY = false
    else
        -- downscroll
        self.line.position.y = -(self.line:getHeight() * 0.5)
        self.line.flipY = false

        self.tail.position.y = -(self.line:getHeight() + (self.tail:getHeight() * 0.5))
        self.tail.flipY = true
    end
    local strum = strumLine:getChild(note.lane + 1) --- @type funkin.gameplay.notes.Strum
    
    local baseX, baseY = strumLine.position.x + strum.position.x + self.offsetX, strumLine.position.y + strum.position.y + self.offsetY
    self.position.x = baseX
    self.position.y = baseY + (0.45 * ((note.time + sexo) - Conductor.instance:getCurrentPlayhead()) * speed)

    self.visible = self.note.length > 0
    if self.visible then
        local tail, strumCenter = self.tail, strumLine.position.y + strum.position.y

        local ry = baseY + (tail.position.y - (tail:getHeight() * 0.5))
        local clipRect = (tail.clipRect or Rect:new()):set(0, 0, tail:getOriginalWidth(), tail:getOriginalHeight())
        
        if speedSign == 1 then
            -- upscroll
            clipRect.y = (strumCenter - ry) / tail.scale.y
            clipRect.height = (clipRect.height - clipRect.y)
        else
            -- downscroll
            clipRect.height = (strumCenter - ry) / tail.scale.y
            clipRect.y = tail:getOriginalHeight() - clipRect.height
        end
        tail.clipRect = clipRect
    end
end

function Sustain:update(dt)
    super.update(self, dt)
    self:updateVisuals()
end

function Sustain:_draw()
    self.line.alpha = self.alpha
    self.tail.alpha = self.alpha
    super._draw(self)
end

return Sustain