local nativefs = cometreq("lib.nativefs") --- @type comet.lib.nativefs
local Path = cometreq("util.path") --- @type comet.util.Path

local AssetLoader = srcreq("funkin.backend.assets.loaders.assetloader") --- @type funkin.backend.assets.loaders.AssetLoader

--- @class funkin.backend.assets.loaders.DefaultAssetLoader : funkin.backend.assets.loaders.AssetLoader
local DefaultAssetLoader, super = AssetLoader:subclass("DefaultAssetLoader", ...)

function DefaultAssetLoader:__init__()
    super.__init__(self, "DefaultAssetLoader", "assets")
    if nativefs.exists(Path.join({comet.sourceBaseDirectory, "assets"})) then
        self.displayedRoot = "./" .. self.root
    end
end

return DefaultAssetLoader