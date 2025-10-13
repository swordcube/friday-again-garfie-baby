local nativefs = cometreq("lib.nativefs") --- @type comet.lib.nativefs
local Path = cometreq("util.path") --- @type comet.util.Path

local AssetLoader = srcreq("funkin.backend.assets.loaders.assetloader") --- @type funkin.backend.assets.loaders.AssetLoader

--- @class funkin.backend.assets.loaders.ModAssetLoader : funkin.backend.assets.loaders.AssetLoader
local ModAssetLoader, super = AssetLoader:subclass("ModAssetLoader", ...)

function ModAssetLoader:__init__(mod)
    super.__init__(self, "ModAssetLoader", "mods/" .. mod)
    if nativefs.exists(Path.join({comet.sourceBaseDirectory, "mods"})) then
        self.displayedRoot = "./" .. self.root
    else
        self.displayedRoot = self.root
    end
end

return ModAssetLoader