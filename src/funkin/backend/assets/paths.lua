local fs = love.filesystem
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
Paths.FONT_EXTS = {
    ".ttf",
    ".otf"
}
Paths.SOUND_EXTS = {
    ".ogg",
    ".wav",
    ".mp3"
}

--- @type funkin.backend.assets.loaders.AssetLoader[]
Paths._registeredAssetLoaders = {} --- @protected

local function fallback(name, assetType, printError)
    printError = printError ~= nil and printError or true
    if printError then
        if assetType then
            FLog.warn(assetType .. " asset not found: " .. name)
        else
            FLog.warn("Asset not found: " .. name)
        end
    end
    return name
end

function Paths.reloadContent()
    Paths._registeredAssetLoaders = {}
    table.insert(Paths._registeredAssetLoaders, 1, DefaultAssetLoader:new())
end

function Paths.initAssetSystem()
    Paths.reloadContent()
end

function Paths.getAsset(name, assetType, printError)
    local assetLoaders = Paths._registeredAssetLoaders
    for i = 1, #assetLoaders do
        local loader = assetLoaders[i] --- @type funkin.backend.assets.loaders.AssetLoader
        local path = loader:getPath(name)
        if fs.exists(path) then
            return path
        end
    end
    return fallback(name, assetType, printError)
end

function Paths.image(name)
    local assetExts = Paths.IMAGE_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], nil, false)
        if fs.exists(newPath) then
            return newPath
        end
    end
    return fallback(name, "Image")
end

function Paths.xml(name)
    local newPath = Paths.getAsset(name .. ".xml", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "XML")
end

function Paths.json(name)
    local newPath = Paths.getAsset(name .. ".json", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "json")
end

function Paths.csv(name)
    local newPath = Paths.getAsset(name .. ".csv", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "CSV")
end

function Paths.font(name)
    local assetExts = Paths.FONT_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], nil, false)
        if fs.exists(newPath) then
            return newPath
        end
    end
    return fallback(name, "Font")
end

function Paths.music(name)
    name = "menus/music/" .. name .. "/music"
    local assetExts = Paths.SOUND_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], nil, false)
        if fs.exists(newPath) then
            return newPath
        end
    end
    return fallback(name, "Sound")
end

function Paths.musicConfig(name)
    name = "menus/music/" .. name .. "/config"
    local newPath = Paths.getAsset(name .. ".json", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "json")
end

function Paths.sound(name)
    local assetExts = Paths.SOUND_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], nil, false)
        if fs.exists(newPath) then
            return newPath
        end
    end
    return fallback(name, "Sound")
end

function Paths.frag(name)
    local newPath = Paths.getAsset(name .. ".frag", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "Fragment shader")
end

function Paths.vert(name)
    local newPath = Paths.getAsset(name .. ".vert", nil, false)
    if fs.exists(newPath) then
        return newPath
    end
    return fallback(name, "Vertex shader")
end

function Paths.getSparrowAtlas(name)
    -- TODO: caching
    return FrameCollection.loadSparrowAtlas(
        Paths.image(name),
        Paths.xml(name)
    )
end

return Paths