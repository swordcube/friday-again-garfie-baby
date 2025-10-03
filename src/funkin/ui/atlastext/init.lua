local json = cometreq("lib.json") --- @type comet.lib.Json
local fs = love.filesystem

local utf8 = require("utf8")
local Glyph = srcreq("funkin.ui.atlastext.glyph") --- @type funkin.ui.AtlasText.Glyph

--- @class funkin.ui.AtlasText : comet.gfx.Object2D
--- A basic object for displaying text from an atlas instead of a static font.
local AtlasText, super = Object2D:subclass("AtlasText", ...)

function AtlasText:__init__(x, y, font, size, text)
    super.__init__(self, x, y)
    
    self._font = nil --- @type string
    self._fontData = nil --- @type table

    self._size = size --- @type number
    self._text = text --- @type string

    self._alignment = "left" --- @type "left"|"center"|"right"
    self._alpha = 1.0 --- @type number

    --- Tweenable alpha property, to set alpha immediately, use `setAlpha()`
    self.alpha = 1.0 --- @type number
    
    self:setFont(font)
end

function AtlasText:getSize()
    return self._size
end

function AtlasText:setSize(size)
    self._size = size
    self:_regenText()
end

function AtlasText:getFont()
    return self._font
end

--- @param font string
function AtlasText:setFont(font)
    if self._font == font then
        return
    end
    self._font = font
    self._fontData = json.decode(fs.getContent(Paths.json(("fonts/alphabet/%s/config"):format(font))))
    
    if self._atlas then
        self._atlas:dereference()
    end
    self._atlas = Paths.getSparrowAtlas(("fonts/alphabet/%s/%s"):format(self._font, self._fontData.atlas.path))
    self._atlas:reference()
    
    self:_regenText()
end

function AtlasText:getText()
    return self._text
end

function AtlasText:setText(text)
    self._text = text
    self:_regenText()
end

function AtlasText:getAlignment()
    return self._alignment
end

--- @param alignment "left"|"center"|"right"
function AtlasText:setAlignment(alignment)
    self._alignment = alignment
    self:_adjustAlignment()
end

function AtlasText:getAlpha()
    return self._alpha
end

function AtlasText:setAlpha(alpha)
    self._alpha, self.alpha = alpha, alpha
    for i = 1, self:getChildCount() do
        local line = self.children[i]
        for j = 1, #line.children do
            local glyph = line.children[j] --- @type funkin.ui.AtlasText.Glyph
            glyph.alpha = alpha
        end
    end
end

--- @protected
function AtlasText:_regenText()
    local text = self._text
    local glyphX, glyphY, idx = 0, 0, 1

    for i = 1, self:getChildCount() do
        local line = self.children[i]
        for j = 1, #line.children do
            local glyph = line.children[j] --- @type funkin.ui.AtlasText.Glyph
            glyph:kill()
        end
        line:kill()
    end
    local line = self.children[1]
    if not line then
        -- create first line of text
        line = Object2D:new() --- @type comet.gfx.Object2D
        line:kill()
        self:addChild(line)
    end
    local lineCount = 1
    for i = 1, utf8.len(text) do
        local rawGlyph = utf8.char(utf8.codepoint(text, i, i))
        if rawGlyph == "\n" then
            line:revive() -- add this line

            lineCount = lineCount + 1
            line = self.children[lineCount] -- go to next line
            
            -- create this line of text if it doesn't exist yet
            if not line then
                line = Object2D:new() --- @type comet.gfx.Object2D
                line:kill()
                self:addChild(line)
            end
            -- visually progress to new line
            glyphX = 0
            glyphY = glyphY + (self._fontData.lineHeight * self._fontData.scale * self._size)
            line.position.y = glyphY
            
            idx = 1
            goto continue
        end
        local glyph = line.children[idx] --- @type funkin.ui.AtlasText.Glyph
        if not glyph then
            glyph = Glyph:new(self) --- @type funkin.ui.AtlasText.Glyph
            line:addChild(glyph)
        end
        glyph:setup(glyphX, 0, rawGlyph, self._fontData.scale * self._size)
        
        local glyphData = self._fontData.glyphs[glyph.glyph]
        if glyphData and glyphData.visible == false then
            glyphX = glyphX + (glyphData.width * self._fontData.scale * self._size)
        else
            glyphX = glyphX + glyph:getWidth()
        end
        idx = idx + 1
        ::continue::
    end
    if not line.exists then
        line.position.y = glyphY
        line:revive()
    end
    self:_adjustAlignment()
end

function AtlasText:screenCenter(axes)
    -- TODO: this is a dumb hack to make text centering work
    if axes == "x" or axes == "xy" then
        self.position.x = 0.0
    end
    if axes == "y" or axes == "xy" then
        self.position.y = 0.0
    end
    super.screenCenter(self, axes)
end

--- @protected
function AtlasText:_adjustAlignment()
    local fullWidth = 0
    for i = 1, self:getChildCount() do
        local line = self.children[i]
        local w = line:getChildrenBoundingBox().width
        if w > fullWidth then
            fullWidth = w
        end
    end
    for i = 1, self:getChildCount() do
        local line = self.children[i]
        if self._alignment == "left" then
            line.position.x = 0
        
        elseif self._alignment == "center" then
            line.position.x = (fullWidth - line:getChildrenBoundingBox().width) * 0.5
        
        elseif self._alignment == "right" then
            line.position.x = fullWidth - line:getChildrenBoundingBox().width
        end
    end
end

function AtlasText:_draw()
    if self._alpha ~= self.alpha then
        self:setAlpha(self.alpha)
    end
    super._draw(self)
    if comet.settings.debugDraw then
        love.graphics.setLineWidth(4)

        local r = self:getChildrenBoundingBox()
        love.graphics.rectangle("line", r.x, r.y, r.width, r.height)
    end
end

function AtlasText:destroy()
    super.destroy(self)
    if self._atlas then
        self._atlas:dereference()
        self._atlas = nil
    end
end

return AtlasText