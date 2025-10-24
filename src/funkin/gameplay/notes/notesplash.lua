local json = cometreq("lib.json") --- @type comet.lib.Json
local NoteSkin = srcreq("funkin.gameplay.notes.noteskin") --- @type funkin.gameplay.notes.NoteSkin

--- @class funkin.gameplay.notes.NoteSplash : comet.gfx.AnimatedImage
local NoteSplash, super = AnimatedImage:extend("NoteSplash", ...)

local dirs = {"left", "down", "up", "right"}

function NoteSplash:__init__()
    super.__init__(self)

    self.lane = 0
    self.skin = "funkin"
    self.skinData = nil

    self.strumLine = nil --- @type funkin.gameplay.notes.StrumLine
    self.playField = nil --- @type funkin.gameplay.PlayField

    self.animCount = 0
    self.offsetX, self.offsetY = 0.0, 0.0

    self.onComplete:connect(function()
        self:kill()
    end)
end

function NoteSplash:loadSkin(skin)
    self.skin = skin or "funkin"
    self.skinData = NoteSkin.get(self.skin)

    if not self.skinData.splash then
        self.skin = "funkin"
        self.skinData = NoteSkin.get("funkin")
    end
    -- TODO: more than just sparrow atlas!!

    self.animCount = 0
    self:setFrameCollection(Paths.getSparrowAtlas(("game/notes/%s/%s"):format(self.skin, self.skinData.splash.atlas.path)))

    if self.playField then
        self.playField:cacheAtlas(("#_SPLASH_%s"):format(self.skin), self:getFrameCollection())
    end
    for name, d in pairs(self.skinData.splash.animation) do
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
        self.animCount = self.animCount + 1
    end
    if self.skinData.splash.offset then
        self.offset:set(self.skinData.splash.offset[1], self.skinData.splash.offset[2])
    end
    self.alpha = self.skinData.splash.alpha or 1.0
    self.scale:set(self.skinData.splash.scale, self.skinData.splash.scale)
    self.antialiasing = self.skinData.splash.antialiasing ~= nil and self.skinData.splash.antialiasing or true
end

--- @param lane number
--- @param skin string
--- @param strumLine funkin.gameplay.notes.StrumLine
function NoteSplash:setup(lane, skin, strumLine)
    self.lane = lane
    self.strumLine = strumLine

    self:loadSkin(skin or "funkin")
    self.animation:play(dirs[lane + 1] .. "splash" .. tostring(math.floor(love.math.random(1, self.animCount))), true)
end

function NoteSplash:updatePosition()
    local strum = self.strumLine:getChild(self.lane + 1) --- @type funkin.gameplay.notes.Strum
    
    local baseX, baseY = self.strumLine.position.x + strum.position.x + self.offsetX, self.strumLine.position.y + strum.position.y + self.offsetY
    self.position.x = baseX
    self.position.y = baseY
end

function NoteSplash:update(dt)
    super.update(self, dt)
    self:updatePosition()
end

return NoteSplash