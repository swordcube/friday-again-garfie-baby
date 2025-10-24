local fs = cometreq("lib.nativefs") --- @type comet.lib.nativefs
local json = cometreq("lib.json") --- @type comet.lib.Json

local Character = srcreq("funkin.gameplay.character") --- @type funkin.gameplay.Character
local CharacterConfig = srcreq("funkin.gameplay.character.config") --- @type funkin.gameplay.character.Config

--- @class funkin.screens.debug.CharacterEditor : funkin.screens.MusicBeatScreen
local CharacterEditor, super = MusicBeatScreen:extend("CharacterEditor", ...)

function CharacterEditor:enter()
    super.enter(self)

    self.persistentUpdate = true
    CharacterConfig.clearCache()

    self.camera = Camera:new() --- @type comet.gfx.Camera
    self.camera:setBackgroundColor(Color.GRAY)
    self:addChild(self.camera)

    local chosenCharacter = "darnell"
    local config = CharacterConfig.get(chosenCharacter)

    self.shadowCharacter = Character:new(0, 0, chosenCharacter, config.isPlayer) --- @type funkin.gameplay.Character
    self.shadowCharacter.debugMode = true
    self.shadowCharacter:setTint(Color.BLACK)
    self.shadowCharacter.alpha = 0.45
    self.camera:addChild(self.shadowCharacter)
    
    self.character = Character:new(0, 0, chosenCharacter, config.isPlayer) --- @type funkin.gameplay.Character
    self.character.debugMode = true
    self.camera:addChild(self.character)

    self.animLabels = Object2D:new(5, 5) --- @type comet.gfx.Object2D
    self:addChild(self.animLabels)

    local anims = self.character.config.animations
    self.curSelected = 1
    self.lastMousePos = Vec2:new() --- @type comet.math.Vec2

    for i = 1, #anims do
        local anim = anims[i]

        local label = Label:new(0, self.animLabels:getChildCount() * 16) --- @type comet.gfx.Label
        label:setFont(Paths.font("fonts/vcr"))
        label:setSize(16)
        label:setBorderColor(Color.BLACK)
        label.borderSize = 1
        label.text = ("%s%s (%d, %d)"):format(i == self.curSelected and "> " or "  ", anim.name, anim.offset[1], anim.offset[2])
        label.centered = false
        self.animLabels:addChild(label)
    end
    self.camera:focusOn(self.character)
    self:changeSelection(0)
end

function CharacterEditor:changeSelection(by)
    self.curSelected = math.wrap(self.curSelected + by, 1, #self.character.config.animations)
    self.character:playAnimation(self.character.config.animations[self.curSelected].name, true)

    for i = 1, self.animLabels:getChildCount() do
        local anim = self.character.config.animations[i]

        local label = self.animLabels:getChild(i) --- @type comet.gfx.Label
        label.text = ("%s%s (%d, %d)"):format(i == self.curSelected and "> " or "  ", anim.name, anim.offset[1], anim.offset[2])
        label:setColor(i == self.curSelected and Color.CYAN or Color.WHITE)
    end
end

function CharacterEditor:input(e)
    if e.type == "text" then
        return
    end
    if self.controls.justPressed.BACK then
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
        self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
    end
    if e.type == "key" then
        local holdinShift = comet.keys:isPressed("lshift") or comet.keys:isPressed("rshift")
        local holdinCtrl = comet.keys:isPressed("lctrl") or comet.keys:isPressed("rctrl")
        
        if holdinCtrl and comet.keys:wasJustPressed("s") then
            local jsonStr = json.beautify(self.character.config, {newline = "\n", indent = "\t", depth = 0})
            local success, result = pcall(love.filesystem.openNativeFile, Paths.json("game/characters/" .. self.character.name .. "/config"), "w") --- @type love.File
            if success then
                local file = result --- @type love.File
                local fsuccess, ferr = file:write(jsonStr)
                if fsuccess then
                    print(("Saved character config for %s successfully"):format(self.character.name))
                else
                    FLog.error(("Failed to save character config: %s"):format(ferr))
                end
                file:close()
            else
                FLog.error(("Failed to save character config: %s"):format(err))
            end
        else
            if comet.keys:wasJustPressed("space") then
                self.character:playAnimation(self.character.animation:getCurrentAnimation(), self.character.lastAnimContext, true)
            end
            if comet.keys:wasJustPressed("w") then
                self:changeSelection(-1)
            end
            if comet.keys:wasJustPressed("s") then
                self:changeSelection(1)
            end
            local offsetMult = holdinShift and (holdinCtrl and 40 or 10) or 1
            if comet.keys:wasJustPressed("left") then
                self:addAnimOffset(self.character.config.animations[self.curSelected].name, -offsetMult, 0)
            end
            if comet.keys:wasJustPressed("down") then
                self:addAnimOffset(self.character.config.animations[self.curSelected].name, 0, offsetMult)
            end
            if comet.keys:wasJustPressed("up") then
                self:addAnimOffset(self.character.config.animations[self.curSelected].name, 0, -offsetMult)
            end
            if comet.keys:wasJustPressed("right") then
                self:addAnimOffset(self.character.config.animations[self.curSelected].name, offsetMult, 0)
            end
            if comet.keys:wasJustPressed("z") then
                local anims = self.character.config.animations
    
                local anim = anims[self.curSelected]
                table.remove(anims, self.curSelected)
    
                self.curSelected = math.wrap(self.curSelected - 1, 1, #anims + 1)
                table.insert(anims, self.curSelected, anim)
    
                self:changeSelection(0)
            end
            if comet.keys:wasJustPressed("x") then
                local anims = self.character.config.animations
    
                local anim = anims[self.curSelected]
                table.remove(anims, self.curSelected)
    
                self.curSelected = math.wrap(self.curSelected + 1, 1, #anims + 1)
                table.insert(anims, self.curSelected, anim)
    
                self:changeSelection(0)
            end
        end
    end
    if comet.mouse.wheel.y ~= 0 then
        self.camera.zoom.x = self.camera.zoom.x - ((comet.mouse.wheel.y * 0.1) * self.camera.zoom.x)
        self.camera.zoom.y = self.camera.zoom.x
    end
    if e.type == "mousebutton" and e.pressed and (e.button == "left" or e.button == "middle") then
        self.lastMousePos:set(comet.mouse.position.x, comet.mouse.position.y)
    end
end

function CharacterEditor:setAnimOffset(name, x, y)
    self.character.animation:setOffset(name, x, y)
    self.character.config.animations[self.curSelected].offset = {x, y}
    
    self.shadowCharacter.animation:setOffset(name, x, y)

    local label = self.animLabels:getChild(self.curSelected) --- @type comet.gfx.Label
    label.text = ("%s%s (%d, %d)"):format("> ", name, x, y)
end

function CharacterEditor:addAnimOffset(name, x, y)
    local curOffset = self.character.animation:getOffset(name)
    x, y = curOffset.x + x, curOffset.y + y

    self.character.animation:setOffset(name, x, y)
    self.shadowCharacter.animation:setOffset(name, x, y)
    self.character.config.animations[self.curSelected].offset = {x, y}

    local label = self.animLabels:getChild(self.curSelected) --- @type comet.gfx.Label
    label.text = ("%s%s (%d, %d)"):format("> ", name, x, y)
end

function CharacterEditor:update(dt)
    super.update(self, dt)
    if comet.keys:isPressed("j") then
        self.camera.scroll.x = self.camera.scroll.x - (300 * dt)
    end
    if comet.keys:isPressed("l") then
        self.camera.scroll.x = self.camera.scroll.x + (300 * dt)
    end
    if comet.keys:isPressed("i") then
        self.camera.scroll.y = self.camera.scroll.y - (300 * dt)
    end
    if comet.keys:isPressed("k") then
        self.camera.scroll.y = self.camera.scroll.y + (300 * dt)
    end
    if comet.mouse:isPressed("left") then
        local curOffset = self.character.animation:getOffset(self.character.config.animations[self.curSelected].name)
        self:setAnimOffset(
            self.character.config.animations[self.curSelected].name,
            curOffset.x + ((comet.mouse.position.x - self.lastMousePos.x) / self.camera.zoom.x),
            curOffset.y + ((comet.mouse.position.y - self.lastMousePos.y) / self.camera.zoom.y)
        )
        self.lastMousePos:set(comet.mouse.position.x, comet.mouse.position.y)
    end
    if comet.mouse:isPressed("middle") then
        self.camera.scroll:set(
            self.camera.scroll.x - ((comet.mouse.position.x - self.lastMousePos.x) / self.camera.zoom.x),
            self.camera.scroll.y - ((comet.mouse.position.y - self.lastMousePos.y) / self.camera.zoom.y)
        )
        self.lastMousePos:set(comet.mouse.position.x, comet.mouse.position.y)
    end
end

return CharacterEditor