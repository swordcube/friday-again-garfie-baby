local fs = love.filesystem
local Path = cometreq("util.path") --- @type comet.util.Path

--- @class funkin.backend.assets.loaders.AssetLoader
local AssetLoader = Class("AssetLoader", ...)

--- @param name string
--- @param root string
--- @param displayedRoot string?
function AssetLoader:__init__(name, root, displayedRoot)
    self.id = nil --- only used internally by Paths
    self.name = name
    self.root = root
    self.displayedRoot = displayedRoot or root
end

function AssetLoader:getPath(asset)
    local potentialPath = Path.normalize(Path.join({self.root, asset}))
    if fs.exists(potentialPath) then
        return potentialPath
    end
    return Path.normalize(asset)
end

return AssetLoader