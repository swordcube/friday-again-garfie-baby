local DefaultAssetLoader = srcreq("funkin.backend.assets.loaders.defaultassetloader") --- @type funkin.backend.assets.loaders.AssetLoader

--- @class funkin.backend.assets.Paths
local Paths = {}

Paths.IMAGE_EXTS = {
    ".png",
    ".jpg", ".jpeg",
    ".bmp",
    ".tga",
    ".hdr", ".pic",
    ".exr"
}

--- @type funkin.backend.assets.loaders.AssetLoader[]
Paths._registeredAssetLoaders = {} --- @protected

function Paths.reloadContent()
    Paths._registeredAssetLoaders = {}
    table.insert(Paths._registeredAssetLoaders, 1, DefaultAssetLoader:new())
end

function Paths.initAssetSystem()
    Paths.reloadContent()
end

function Paths.getAsset()
    
end

function Paths.image()
    
end

return Paths