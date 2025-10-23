local StickerTransition, super = Transition:subclass("StickerTransition", ...)
StickerTransition.static.stickerPack = "stickers-set-1"

local fs = love.filesystem

function StickerTransition:__init__(type, finishCallback, stickerPack)
    super.__init__(self, type, finishCallback)
    self.stickerPack = stickerPack or vse_temp.stickerPack or StickerTransition.static.stickerPack or "stickers-set-1"
end

function StickerTransition:enter()
    super.enter(self)
    print(("We usin sticker pack: %s"):format(self.stickerPack))

    self.stickerNames = {}

    self.grpStickers = Object2D:new() --- @type comet.gfx.Object2D
    self:addChild(self.grpStickers)

    if self.type == "in" then
        self:startIn()
    else
        self:startOut()
    end
end

function StickerTransition:startOut()
    local ta = RuntimeTextureAtlas.newDynamicSize()
    Paths.iterateDirectory(("transitions/sticker/sets/%s"):format(self.stickerPack), function(path)
        if not fs.isFile(path) then
            goto continue
        end
        local stickerName = Path.withoutExtension(Path.withoutDirectory(path))
        self.stickerNames[#self.stickerNames + 1] = stickerName
        ta:add(love.graphics.newImage(path), stickerName)
        
        ::continue::
    end)
    ta:bake("width")

    local frames = ta:toFrameCollection()
    vse_temp.stickerPack = self.stickerPack
    vse_temp.stickerDataList = {}

    local xPos, yPos = -100, -100
    local stickersCreated = 0

    local gw, gh = comet.getDesiredWidth(), comet.getDesiredHeight()
    local stickerNames, grpStickers = self.stickerNames, self.grpStickers

    while xPos <= gw and stickersCreated < 500 do
        local stickyID = math.floor(math.preciseRandom(1, #stickerNames))

        local sticky = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
        sticky.id = stickyID
        sticky:setFrameCollection(frames)
        sticky.animation:addByName("s", stickerNames[stickyID], 0, false)
        sticky.animation:play("s", true)
        sticky.visible = false
        
        sticky.position:set(xPos + (sticky:getOriginalWidth() / 2), yPos + (sticky:getOriginalHeight() / 2))
        xPos = xPos + (sticky:getOriginalWidth() / 2)
        
        if xPos >= gw then
            if yPos <= gh then
                xPos = -100
                yPos = yPos + math.preciseRandom(70, 120)
            end
        end
        sticky.rotation = math.preciseRandom(-60, 70)
        grpStickers:addChild(sticky)

        stickersCreated = stickersCreated + 1
    end
    love.math.shuffle(grpStickers.children)
    
    for i = 1, grpStickers:getChildCount() do
        local sticker = grpStickers:getChild(i) --- @type comet.gfx.AnimatedImage
        local randomScale = math.preciseRandom(0.97, 1.02)

        vse_temp.stickerDataList[#vse_temp.stickerDataList + 1] = {
            name = stickerNames[sticker.id],
            x = sticker.position.x,
            y = sticker.position.y,
            scale = randomScale,
            rotation = sticker.rotation
        }
        local timing = math.remapToRange(i - 1, 0, grpStickers:getChildCount(), 0, 0.9)
        Timer.wait(timing, function()
            sticker.visible = true
            comet.mixer:play(Paths.sound(("transitions/sticker/sfx/keyClick%d"):format(math.floor(math.preciseRandom(1, 8)))))

            local frameTimer = math.floor(math.preciseRandom(0, 2))
            Timer.wait((1 / 24) * frameTimer, function()
                sticker.scale:set(randomScale, randomScale)

                if i == grpStickers:getChildCount() then
                    Timer.wait((1 / 24) * 12, function()
                        self:finish()
                    end)
                end
            end)
        end)
    end
end

function StickerTransition:startIn()
    local ta = RuntimeTextureAtlas.newDynamicSize()
    Paths.iterateDirectory(("transitions/sticker/sets/%s"):format(self.stickerPack), function(path)
        if not fs.isFile(path) then
            goto continue
        end
        local stickerName = Path.withoutExtension(Path.withoutDirectory(path))
        self.stickerNames[#self.stickerNames + 1] = stickerName
        ta:add(love.graphics.newImage(path), stickerName)
        
        ::continue::
    end)
    ta:bake("width")

    local frames = ta:toFrameCollection()
    local stickerDataList = vse_temp.stickerDataList
    
    local grpStickers = self.grpStickers
    for i = 1, #stickerDataList do
        local stickerData = stickerDataList[i]

        local sticky = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
        sticky:setFrameCollection(frames)
        sticky.animation:addByName("s", stickerData.name, 0, false)
        sticky.animation:play("s", true)
        sticky.visible = true
        
        sticky.position:set(stickerData.x, stickerData.y)
        sticky.rotation = stickerData.rotation

        sticky.scale:set(stickerData.scale, stickerData.scale)
        grpStickers:addChild(sticky)

        local timing = math.remapToRange(i - 1, 0, #stickerDataList, 0, 0.9)
        Timer.wait(timing, function()
            sticky.visible = false
            comet.mixer:play(Paths.sound(("transitions/sticker/sfx/keyClick%d"):format(math.floor(math.preciseRandom(1, 8)))))

            if i == grpStickers:getChildCount() then
                self:finish()
            end
        end)
    end
    vse_temp.stickerPack = nil
    vse_temp.stickerDataList = nil
end

return StickerTransition