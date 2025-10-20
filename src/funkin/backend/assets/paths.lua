local fs = love.filesystem
local json = cometreq("lib.json") --- @type comet.lib.Json

local Path = cometreq("util.path") --- @type comet.util.Path
local CoolUtil = srcreq("funkin.util.coolutil") --- @type funkin.util.CoolUtil

local GlobalScript = srcreq("funkin.scripting.globalscript") --- @type funkin.scripting.GlobalScript

local DefaultAssetLoader = srcreq("funkin.backend.assets.loaders.defaultassetloader") --- @type funkin.backend.assets.loaders.AssetLoader
local ModAssetLoader = srcreq("funkin.backend.assets.loaders.modassetloader") --- @type funkin.backend.assets.loaders.ModAssetLoader

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
Paths.SCRIPT_EXTS = {
    ".lua"
}
Paths.MODS_DIRECTORY = "mods"

--- @type funkin.backend.assets.loaders.AssetLoader[]
Paths._registeredAssetLoaders = {} --- @protected

--- @type table<string, funkin.backend.assets.loaders.AssetLoader>
Paths._registeredAssetLoadersCache = {} --- @protected

--- @type string[]
Paths.modFolders = {}

--- @type string[]
Paths.mods = {}

--- @type table<string, string>
Paths.modsToFolders = {}

--- @type table<string, string>
Paths.foldersToMods = {}

--- @type table<string, table>
Paths.modMetadata = {}

--- @type table<string, comet.gfx.FrameCollection>
Paths._atlasCache = {} --- @protected

--- @type table
Paths._existingPathCache = {} --- @protected

Paths.forceContentPack = nil

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

--- @param loader funkin.backend.assets.loaders.AssetLoader
function Paths.registerAssetLoader(id, loader)
    if Paths._registeredAssetLoadersCache[id] then
        return
    end
    loader.id = id
    Paths._registeredAssetLoadersCache[id] = loader
    table.insert(Paths._registeredAssetLoaders, 1, loader)
end

function Paths.reloadMods()
    Paths._registeredAssetLoaders, Paths._registeredAssetLoadersMap, Paths.modMetadata, Paths._existingPathCache = {}, {}, {}, {}
    Paths.modsToFolders, Paths.foldersToMods, Paths.modFolders, Paths.mods = {}, {}, {}, {}

    Paths.modMetadata["default"] = json.parse(fs.getContent("assets/metadata.json"))
    Paths.registerAssetLoader("default", DefaultAssetLoader:new())

    local mdir = Paths.MODS_DIRECTORY
    if fs.isDirectory(mdir) then
        local function iterate(d)
            local items = fs.getDirectoryItems(d)
            for i = 1, #items do
                local item = ("%s/%s"):format(d, items[i])
                if fs.isDirectory(item) then
                    local metaPath = ("%s/metadata.json"):format(item)
                    if fs.isFile(metaPath) then
                        FLog.verbose(("%s has metadata, we gonna try to load it!"):format(item))

                        local meta = CoolUtil.parseJson(metaPath)
                        if meta.id then
                            local folder = item:sub(#mdir + 2)
                            Paths.modsToFolders[meta.id] = folder
                            Paths.foldersToMods[folder] = meta.id
                            
                            table.insert(Paths.modFolders, folder)
                            table.insert(Paths.mods, meta.id)

                            Paths.registerAssetLoader(meta.id, ModAssetLoader:new(folder))
                        else
                            FLog.error(("%s does not specify an ID, we skipping it!"):format(item))
                        end
                    else
                        iterate(item)
                    end
                end
            end
        end
        iterate(mdir)
    end
    if GlobalScript.scripts then
        GlobalScript.reloadScripts()
    end
end

function Paths.initAssetSystem()
    Paths.reloadMods()
end

--- @param path string
function Paths.exists(path)
    if not path then
        return false
    end
    if path:charAt(1) == "." or Path.withoutDirectory(path):charAt(1) == "." then
        return false
    end
    return fs.exists(path)
end

--- @param dir        string
--- @param callback   function
--- @param recursive  boolean?
function Paths.iterateDirectory(dir, callback, recursive)
    local assetLoaders = Paths._registeredAssetLoaders
    for i = 1, #assetLoaders do
        local loader = assetLoaders[i] --- @type funkin.backend.assets.loaders.AssetLoader
        local dirPath = loader:getPath(dir)
        if not Paths.exists(dirPath) then
            goto continue
        end
        local dirItems = fs.getDirectoryItems(dirPath)
        for j = 1, #dirItems do
            local itemPath = ("%s/%s"):format(dirPath, dirItems[j])
            if recursive and Paths.exists(itemPath) and fs.getInfo(itemPath, "directory") ~= nil then
                Paths.iterateDirectory(itemPath, callback, recursive)
            elseif Paths.exists(itemPath) then
                callback(itemPath)
            end
        end
        ::continue::
    end
end

function Paths.getAsset(name, contentPack, useFallback, assetType, printError)
    if contentPack == nil then
        contentPack = Paths.forceContentPack
    end
    if useFallback == nil then
        useFallback = true
    end
    local existingPathCache = Paths._existingPathCache
    if contentPack == nil or #contentPack == 0 then
        local assetLoaders = Paths._registeredAssetLoaders
        for i = 1, #assetLoaders do
            local loader = assetLoaders[i] --- @type funkin.backend.assets.loaders.AssetLoader
            local path = loader:getPath(name)
            if not existingPathCache[path] and Paths.exists(path) then
                existingPathCache[path] = true
            end
            if existingPathCache[path] then
                return path
            end
        end
    else
        local loader = Paths._registeredAssetLoadersCache[contentPack] --- @type funkin.backend.assets.loaders.AssetLoader
        local path = loader:getPath(name)
        if not existingPathCache[path] or Paths.exists(path) then
            existingPathCache[path] = true
        end
        if existingPathCache[path] then
            return path
        
        elseif useFallback then
            local assetLoaders = Paths._registeredAssetLoaders
            for i = 1, #assetLoaders do
                loader = assetLoaders[i] --- @type funkin.backend.assets.loaders.AssetLoader
                local modMetadata = Paths.modMetadata[loader.id]
                if modMetadata and not modMetadata.runGlobally and Paths.forceContentPack ~= loader.id then
                    goto continue
                end
                path = loader:getPath(name)
                if not existingPathCache[path] and Paths.exists(path) then
                    existingPathCache[path] = true
                end
                if existingPathCache[path] then
                    return path
                end
                ::continue::
            end
        end
    end
    return useFallback and fallback(name, assetType, printError) or nil
end

function Paths.image(name, contentPack, useFallback)
    local assetExts = Paths.IMAGE_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], contentPack, useFallback, nil, false)
        if Paths.exists(newPath) then
            return newPath
        end
    end
    return useFallback and fallback(name, "Image") or nil
end

function Paths.xml(name, contentPack, useFallback)
    local newPath = Paths.getAsset(name .. ".xml", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "XML") or nil
end

function Paths.txt(name, contentPack, useFallback)
    local newPath = Paths.getAsset(name .. ".txt", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "TXT") or nil
end

function Paths.json(name, contentPack, useFallback)
    local newPath = Paths.getAsset(name .. ".json", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "Json") or nil
end

function Paths.csv(name, contentPack, useFallback)
    local newPath = Paths.getAsset(name .. ".csv", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "CSV") or nil
end

function Paths.script(name, contentPack, useFallback)
    local newPath = Paths.getAsset(name .. ".lua", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "Lua script") or nil
end

function Paths.font(name, contentPack, useFallback)
    local assetExts = Paths.FONT_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], contentPack, useFallback, nil, false)
        if Paths.exists(newPath) then
            return newPath
        end
    end
    return useFallback and fallback(name, "Font") or nil
end

function Paths.music(name, contentPack, useFallback)
    name = "menus/music/" .. name .. "/music"
    local assetExts = Paths.SOUND_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], contentPack, useFallback, nil, false)
        if Paths.exists(newPath) then
            return newPath
        end
    end
    return useFallback and fallback(name, "Sound") or nil
end

function Paths.musicConfig(name, contentPack, useFallback)
    name = "menus/music/" .. name .. "/config"
    local newPath = Paths.getAsset(name .. ".json", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "json") or nil
end

function Paths.sound(name, contentPack, useFallback)
    local assetExts = Paths.SOUND_EXTS
    for j = 1, #assetExts do
        local newPath = Paths.getAsset(name .. assetExts[j], contentPack, useFallback, nil, false)
        if Paths.exists(newPath) then
            return newPath
        end
    end
    return useFallback and fallback(name, "Sound") or nil
end

function Paths.inst(song, mix, contentPack, useFallback)
    return Paths.sound(("songs/%s/%s/music/inst"):format(song, mix), contentPack, useFallback)
end

function Paths.vocalTrack(song, mix, name, contentPack, useFallback)
    return Paths.sound(("songs/%s/%s/music/%s"):format(song, mix, name), contentPack, useFallback)
end

function Paths.frag(name, contentPack, useFallback)
    local newPath = Paths.getAsset("shaders/" .. name .. ".frag", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "Fragment shader") or nil
end

function Paths.vert(name, contentPack, useFallback)
    local newPath = Paths.getAsset("shaders/" .. name .. ".vert", contentPack, useFallback, nil, false)
    if Paths.exists(newPath) then
        return newPath
    end
    return useFallback and fallback(name, "Vertex shader") or nil
end

function Paths.getSparrowAtlas(name, contentPack, useFallback)
    local img, xml = Paths.image(name, contentPack, useFallback), Paths.xml(name, contentPack, useFallback)
    local key = ("#_SPARROW_ATLAS_%s/%s"):format(img, xml)
    if not Paths._atlasCache[key] then
        local atlas = FrameCollection.loadSparrowAtlas(img, xml)
        local d = atlas.destroy
        atlas.destroy = function(a)
            -- remove from cache when destroyed
            Paths._atlasCache[key] = nil
            d(a)
        end
        Paths._atlasCache[key] = atlas
    end
    return Paths._atlasCache[key]
end

function Paths.getModFolderFromPath(path, includeContainerFolders)
    if includeContainerFolders == nil then
        includeContainerFolders = false
    end
    path = path:replace("\\", "/") -- i hate windows

    local modFolders = Paths.modFolders
    for i = 1, #modFolders do
        local rawModFolder = modFolders[i]
        if path:startsWith(("%s/%s"):format(Paths.MODS_DIRECTORY, rawModFolder)) then
            return (not includeContainerFolders) and rawModFolder:sub(1, rawModFolder:lastIndexOf("/") + 1) or rawModFolder
        end
    end
    return "assets"
end

function Paths.getModFromPath(path)
    return Paths.foldersToMods[Paths.getModFolderFromPath(path, true)]
end

return Paths