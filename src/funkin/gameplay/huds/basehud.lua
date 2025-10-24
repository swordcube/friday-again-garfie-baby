--- @class funkin.gameplay.huds.BaseHUD : comet.gfx.Object2D 
local BaseHUD, super = Object2D:extend("BaseHUD", ...)

function BaseHUD:__init__(playField, name)
    super.__init__(self)

    self.playField = playField --- @type funkin.gameplay.PlayField
    self.name = name --- @type string

    self.iconP2 = nil --- @type funkin.gameplay.ui.HealthIcon
    self.iconP1 = nil --- @type funkin.gameplay.ui.HealthIcon
end

function BaseHUD:getHUDImage(name)
    return Paths.image(("game/hud/%s/images/%s"):format(self.name, name))
end

function BaseHUD:updateHealthBar(health, min, max) end
function BaseHUD:updatePlayerStats(stats) end
function BaseHUD:updateIcons() end

return BaseHUD