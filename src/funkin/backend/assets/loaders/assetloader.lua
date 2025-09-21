local Path = cometreq("util.path") --- @type comet.util.Path

--- @class funkin.backend.assets.loaders.AssetLoader
local AssetLoader = Class("AssetLoader", ...)

--- @param name string
--- @param root string
--- @param displayedRoot string?
function AssetLoader:__init__(name, root, displayedRoot)
    self.name = name
    self.root = root
    self.displayedRoot = displayedRoot or root
end

function AssetLoader:getPath(asset)
    return Path.normalize(Path.join({self.root, asset}))
end

return AssetLoader