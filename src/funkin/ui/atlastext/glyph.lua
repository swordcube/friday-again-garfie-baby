--- @class funkin.ui.AtlasText.Glyph : comet.gfx.AnimatedImage
local Glyph, super = AnimatedImage:extend("AtlasText.Glyph", ...)

local allLetters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}

function Glyph:__init__(text)
    super.__init__(self)
    self.centered = false
    self.glyph = nil
    self.text = text --- @type funkin.ui.AtlasText
end

function Glyph:setup(x, y, glyph, size)
    self:revive()
    self.position:set(x, y)
    
    local fontData = self.text._fontData
    self:setFrameCollection(self.text._atlas)
    
    if fontData.noLowerCase and table.contains(allLetters, glyph:upper()) then
        glyph = glyph:upper()
    end
    self.glyph = glyph
    
    local glyphData = fontData.glyphs[glyph]
    local name = glyphData and (glyphData.prefix or glyph) or glyph
    if not fontData.noLowerCase and table.contains(allLetters, glyph:upper()) then
        local lowercase = glyph:upper() ~= glyph
        name = lowercase and (glyph:lower() .. " lowercase") or (glyph:upper() .. " capital")
    end
    if glyphData and glyphData.visible == false then
        self:kill()
        return
    end
    self.animation:addByName("idle", name, fontData.fps or 24, true)

    if self:hasAnimation("idle") then
        self.animation:play("idle", true)
        self:setAnimationOffset("idle", -((glyphData and glyphData.offset) and glyphData.offset[1] or 0.0), -(((glyphData and glyphData.offset) and glyphData.offset[2] or 0.0)))
    end
    self.scale:set(size, size)
    self.offset.y = (110 - self:getHeight())
end

return Glyph