--- @class funkin.gameplay.Stage : comet.gfx.Object2D
local Stage, super = Object2D:subclass("Stage", ...)

function Stage:__init__(name)
    super.__init__(self)

    self.name = name or "stage"
    self.config = CoolUtil.parseJson(Paths.json(("game/stages/%s/config"):format(self.name)))
    self.props = {}

    if not self.config.directory then
        self.config.directory = ("game/stages/%s/images"):format(self.name)
    end
    self.script = Script:new(Paths.script(("game/stages/%s/script"):format(self.name))) --- @type funkin.scripting.Script
    self.script:linkObject(self)
    self.script:call("onLoad")

    self.lastLayer = nil --- @type comet.gfx.Parallax2D
    self.lastScrollFactor = Vec2:new(-math.huge, -math.huge) --- @type comet.math.Vec2

    local propDatas = self.config.props --- @type table[]

    for i = 1, #propDatas do
        local propData = propDatas[i]
        local propType = propData.type or "sprite" --- @type "sprite"|"box"

        local prop = nil --- @type any
        if propType == "sprite" then
            local atlasType = propData.atlasType or "none" --- @type "none"|"sparrow"|"opponent"|"spectator"|"player"
            if atlasType == "none" then
                prop = Image:new(Paths.image(("%s/%s"):format(self.config.directory, propData.assetPath))) --- @type comet.gfx.Image
            
            elseif atlasType == "sparrow" then
                prop = AnimatedImage:new() --- @type comet.gfx.AnimatedImage
                prop:setFrameCollection(Paths.getSparrowAtlas(("%s/%s"):format(self.config.directory, propData.assetPath)))

                local anims = propData.animations or {}
                for j = 1, #anims do
                    local anim = anims[j]
                    if anim.indices and #anim.indices ~= 0 then
                        prop:addAnimationByIndices(anim.shortcut or anim.name, anim.prefix or anim.name, anim.indices, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
                    else
                        prop:addAnimationByName(anim.shortcut or anim.name, anim.prefix or anim.name, anim.fps ~= nil and anim.fps or anim.frameRate, anim.loop ~= nil and anim.loop or anim.looped)
                    end
                    if anim.offset then
                        prop:setAnimationOffset(anim.shortcut or anim.name, anim.offset[1] or 0.0, anim.offset[2] or 0.0)
                    end
                end
                prop:playAnimation(propData.idleAnim or (anims[1] and (anims[1].shortcut or anims[1].name) or "idle") or "idle")
            end
            prop.position:set(
                propData.position and (propData.position[1] or 0.0) or 0.0,
                propData.position and (propData.position[2] or 0.0) or 0.0
            )
            prop.scale:set(
                propData.scale and (propData.scale[1] or 1.0) or 1.0,
                propData.scale and (propData.scale[2] or 1.0) or 1.0
            )
            prop.alpha = propData.alpha or 1.0
            prop.rotation = propData.rotation or 0.0
            if propData.centered ~= nil then
                prop.centered = propData.centered
            else
                prop.centered = true
            end
            prop.flipX = propData.flipX ~= nil and propData.flipX or false
            prop.flipY = propData.flipY ~= nil and propData.flipY or false

        elseif propType == "box" then
            -- TODO: box prop type

        elseif propType == "opponent" or propType == "spectator" or propType == "player" then
            prop = Rectangle:new() --- @type comet.gfx.Rectangle
            prop.position:set(
                propData.position and (propData.position[1] or 0.0) or 0.0,
                propData.position and (propData.position[2] or 0.0) or 0.0
            )
            prop.size:set(20, 20)
            prop:setColor(Color.RED)

            propData.name = propType
        end
        if not propData.scroll then
            propData.scroll = {1.0, 1.0}
        end
        self:addProp(propData.name, prop, propData.scroll)
    end
    self.script:call("onLoadPost")
end

function Stage:getStageImage(img)
    return Paths.image(("%s/%s"):format(self.config.directory, img))
end

function Stage:addProp(name, prop, scroll)
    scroll = scroll or {1.0, 1.0}
    if scroll[1] ~= self.lastScrollFactor.x or scroll[2] ~= self.lastScrollFactor.y then
        self.lastScrollFactor:set(scroll[1], scroll[2])
        
        self.lastLayer = Parallax2D:new() --- @type comet.gfx.Parallax2D
        self.lastLayer.scrollFactor:set(self.lastScrollFactor.x, self.lastScrollFactor.y)
        self:addChild(self.lastLayer)
    end
    self.props[name] = prop
    self.lastLayer:addChild(prop)
end

function Stage:insertProp(name, prop, scroll, layerIndex)
    local madeLayer = false
    scroll = scroll or {1.0, 1.0}

    if scroll[1] ~= self.lastScrollFactor.x or scroll[2] ~= self.lastScrollFactor.y then
        self.lastScrollFactor:set(scroll[1], scroll[2])
        
        self.lastLayer = Parallax2D:new() --- @type comet.gfx.Parallax2D
        self.lastLayer.scrollFactor:set(self.lastScrollFactor.x, self.lastScrollFactor.y)
        self:insertChild(layerIndex, self.lastLayer)

        madeLayer = true
    end
    self.props[name] = prop
    if madeLayer then
        self.lastLayer:addChild(prop)
    else
        self.lastLayer:insertChild(layerIndex, prop)
    end
end

function Stage:_update(dt)
    self.script:call("onUpdatePre", dt)
    super._update(self, dt)
    self.script:call("onUpdatePost", dt)
end

function Stage:update(dt)
    self.script:call("onUpdate", dt)
end

function Stage:beatHit(beat)
    self.script:call("onBeatHit", beat)
end

function Stage:destroy()
    super.destroy(self)

    if self.script then
        self.script:close()
        self.script = nil
    end
end

return Stage