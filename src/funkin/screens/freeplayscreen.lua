local fs = love.filesystem
local AtlasTextMenu = srcreq("funkin.ui.atlastextmenu") --- @type funkin.ui.AtlasTextMenu

--- @class funkin.screens.FreeplayScreen : funkin.screens.MusicBeatScreen
local FreeplayScreen = MusicBeatScreen:subclass("FreeplayScreen", ...)

function FreeplayScreen:enter()
    self.persistentUpdate = true

    if not comet.mixer.music:isPlaying() then
        CoolUtil.playMenuMusic()
    end
    self.bg = Image:new() --- @type comet.gfx.Image
    self.bg:loadTexture(Paths.image("menus/bg_blue"))
    self.bg:screenCenter("xy")
    self:addChild(self.bg)

    self.songs = {}

    self.menu = AtlasTextMenu:new() --- @type funkin.ui.AtlasTextMenu
    self:addChild(self.menu)

    local assetLoaders = Paths._registeredAssetLoaders
    for i = 1, #assetLoaders do
        local loader = assetLoaders[i] --- @type funkin.backend.assets.loaders.AssetLoader

        local orderFile = Paths.txt("levels/order", loader.id)
        if not fs.exists(orderFile) then
            goto skip
        end
        local levelOrder = fs.getContent(orderFile):replace("\r", "\n"):split("\n")
        for j = 1, #levelOrder do
            local levelData, err = CoolUtil.parseJson(Paths.json(("levels/%s"):format(levelOrder[j]), loader.id))
            if not levelData then
                FLog.warn(("Failed to load level (%s) from %s: %s"):format(levelOrder[j], loader.id, err))
                goto continue
            end
            local songs = levelData.songs
            local hiddenSongs = levelData.hiddenSongs or {
                story = {},
                freeplay = {}
            }
            if not hiddenSongs.freeplay then
                hiddenSongs.freeplay = {}
            end
            for k = 1, #songs do
                local id = songs[k] --- @type string
                if not table.contains(hiddenSongs, id) then
                    table.insert(self.songs, {
                        id = id,
                        contentPack = loader.id
                    })
                    self:addSong(id, loader.id)
                end
            end
            ::continue::
        end
        ::skip::
    end
end

function FreeplayScreen:addSong(id, contentPack)
    local metadata, err = CoolUtil.parseJson(Paths.json(("songs/%s/default/metadata"):format(id), contentPack))
    if not metadata then
        FLog.warn(("Failed to load default song metadata for %s from %s: %s"):format(id, contentPack, err))
    end
    -- TODO: parsin vslice metadata temporarily i just wanna get something working here
    self.menu:addItem(metadata and metadata.songName or id)
end

function FreeplayScreen:input(_)
    if self.controls.justPressed.BACK then
        self.persistentUpdate = false
        self:switchTo(srcreq("funkin.screens.mainmenuscreen"):new())
        comet.mixer:play(Paths.sound("menus/sfx/cancel"))
    end
    if self.controls.justPressed.ACCEPT then
        self.persistentUpdate = false
        self:switchTo(function()
            return srcreq("funkin.screens.playscreen"):new({
                song = self.songs[self.menu.curSelected].id,
                difficulty = "hard",
                mix = "default",
                contentPack = self.songs[self.menu.curSelected].contentPack
            })
        end)
    end
end

return FreeplayScreen