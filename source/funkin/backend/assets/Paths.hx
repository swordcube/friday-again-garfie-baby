package funkin.backend.assets;

import haxe.io.Path;
import haxe.ds.ReadOnlyArray;

import sys.io.File;
import sys.FileSystem;

import openfl.text.Font;
import openfl.media.Sound;
import openfl.display.BitmapData;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.frontEnds.AssetFrontEnd;

import animate.FlxAnimateFrames;

import funkin.backend.LevelData;
import funkin.backend.ContentMetadata;

import funkin.backend.assets.loaders.AssetLoader;
import funkin.backend.assets.loaders.ContentAssetLoader;
import funkin.backend.assets.loaders.DefaultAssetLoader;

enum AssetType {
    IMAGE;
    SOUND;
    VIDEO;
    FONT;
    JSON;
    XML;
    SCRIPT;
}

#if SCRIPTING_ALLOWED
@:allow(funkin.scripting.GlobalScript)
#end
@:allow(funkin.backend.LevelData)
class Paths {
    public static final ASSET_EXTENSIONS:Map<AssetType, Array<String>> = [
        IMAGE => [".png", ".jpg", ".jpeg", ".bmp"],
        SOUND => [".ogg", ".wav", ".mp3"],
        VIDEO => [".mp4", ".mkv", ".ogv", ".avi", ".flv", ".3gp", ".avif"],
        FONT => [".ttf", ".otf"],
        SCRIPT => [".hx", ".hxs", ".hsc", ".hscript", ".lua"]
    ];
    public static final CONTENT_DIRECTORY:String = "content";

    public static var forceContentPack:String = null;

    /**
     * A list of every registered content pack (raw folder paths).
     * 
     * This is mainly for internal stuff, if you want to search
     * through all content packs and retrieve their metadata, use the `contentPacks` list instead.
     */
    public static var contentFolders:Array<String> = [];

    /**
     * A map of metadata ids to raw folder paths.
     */
    public static var contentPacksToFolders:Map<String, String> = [];

    /**
     * A map of raw folder paths to metadata ids.
     */
    public static var contentFoldersToPacks:Map<String, String> = [];

    /**
     * A list of every registered content pack (metadata ids, folder name as fallback).
     */
    public static var contentPacks:Array<String> = [];

    public static var contentMetadata:Map<String, ContentMetadata> = [];

    /**
     * A list of every registered asset loader.
     * 
     * NOTE: Trying to modify this list won't work, since getting
     * this list just returns a read-only copy!
     */
    public static var registeredAssetLoaders(get, never):ReadOnlyArray<AssetLoader>;

    public static function initAssetSystem():Void {
        @:privateAccess
        FlxG.assets.exists = (id:String, ?type:FlxAssetType) -> {
            if (id == null) // no clue what's being sent null, but fixes hl shit so idc???
                return false;

            #if FLX_DEFAULT_SOUND_EXT
            // add file extension
            if (type == SOUND)
                id = addSoundExt(id);
            #end
            
            if (FlxG.assets.useOpenflAssets(id))
                return OpenFLAssets.exists(id, type.toOpenFlType());

            // Can't verify contents, match expected type without
            return FileSystem.exists(id);
        }
        @:privateAccess
        FlxG.assets.getAssetUnsafe = (id:String, type:FlxAssetType, useCache = true) -> {
            id = sanitizePath(id); // just incase the path wasn't gotten from the functions in this class

            if(FlxG.assets.useOpenflAssets(id))
                return FlxG.assets.getOpenflAssetUnsafe(id, type, useCache);
            
            // load from custom assets directory
            final canUseCache = useCache && OpenFLAssets.cache.enabled;
            
            final asset:Any = switch(type) {
                // No caching
                case TEXT:
                    File.getContent(id);
                
                case BINARY:
                    File.getBytes(id);
                
                // Check cache
                case IMAGE if (canUseCache && OpenFLAssets.cache.hasBitmapData(id)):
                    OpenFLAssets.cache.getBitmapData(id);
                
                case SOUND if (canUseCache && OpenFLAssets.cache.hasSound(id)):
                    OpenFLAssets.cache.getSound(id);
                
                case FONT if (canUseCache && OpenFLAssets.cache.hasFont(id)):
                    OpenFLAssets.cache.getFont(id);
                
                // Get asset and set cache
                case IMAGE:
                    final bitmap = BitmapData.fromFile(id);
                    if (canUseCache)
                        OpenFLAssets.cache.setBitmapData(id, bitmap);
                    bitmap;
                
                case SOUND:
                    final sound = Sound.fromFile(id);
                    if (canUseCache)
                        OpenFLAssets.cache.setSound(id, sound);
                    sound;
                
                case FONT:
                    final font = Font.fromFile(id);
                    if (canUseCache)
                        OpenFLAssets.cache.setFont(id, font);
                    font;
            }
            
            return asset;
        }
        FlxG.assets.list = (?type:FlxAssetType) -> {
            // list all files in the directory, recursively
            final list = [];
            function addFiles(directory:String, prefix = "")
            {
                for (path in sys.FileSystem.readDirectory(directory))
                {
                    if (sys.FileSystem.isDirectory('$directory/$path'))
                        addFiles('$directory/$path', prefix + path + '/');
                    else
                        list.push(prefix + path);
                }
            }
            final loaders:Array<AssetLoader> = _registeredAssetLoaders;
            for(i in 0...loaders.length)
                addFiles(loaders[i].root);
            
            return list;
        };
        FlxG.bitmap.autoClearCache = false;
        reloadContent();
    }

    public static function registerAssetLoader(id:String, loader:AssetLoader, ?priority:Int = 0):Void {
        if(_registeredAssetLoadersMap.exists(id)) {
            FlxG.log.warn("You cannot register an asset loader with the same ID twice!");
            return;
        }
        loader.id = id;
        _registeredAssetLoaders.insert(_registeredAssetLoaders.length - priority - 1, loader);
        _registeredAssetLoadersMap.set(id, loader);
    }

    public static function unregisterAssetLoader(id:String):Void {
        if(!_registeredAssetLoadersMap.exists(id)) {
            FlxG.log.warn("You cannot unregister an asset loader that doesn't exist!");
            return;
        }
        _registeredAssetLoaders.remove(_registeredAssetLoadersMap.get(id));
        _registeredAssetLoadersMap.remove(id);
    }

    /**
     * Returns the content directory used by the game
     * to load in new content packs.
     * 
     * Mainly used to find content packs in the directory
     * of the engine's source code rather than the export folder
     * when compiling a build.
     */
    public static function getContentDirectory():String {
        final liveReload:Bool = #if TEST_BUILD true #else Sys.args().contains("-livereload") #end;
        return '${(liveReload) ? "../../../../" : ""}${CONTENT_DIRECTORY}';
    }

    /**
     * Scans for any content packs inside the content directory
     * and loads them if they exist.
     * 
     * This will clear out any previously loaded content packs.
     */
    public static function reloadContent():Void {
        contentFolders.clear();
        contentPacks.clear();
        contentMetadata.clear();

        contentPacksToFolders.clear();
        contentFoldersToPacks.clear();

        final contentDir:String = getContentDirectory();
        function iterateThruContent(items:Array<String>):Void {
            for(i in 0...items.length) {
                final item:String = items[i];
                if(!FileSystem.isDirectory('${contentDir}/${item}'))
                    continue;
                
                if(FileSystem.exists('${contentDir}/${item}/metadata.json'))
                    contentFolders.push(item); // assume a content pack
                
                else if(FileSystem.isDirectory('${contentDir}/${item}')) {
                    final dirItems:Array<String> = FileSystem.readDirectory('${contentDir}/${item}');
                    for(j in 0...dirItems.length)
                        dirItems[j] = '${item}/${dirItems[j]}';
                    
                    iterateThruContent(dirItems); // assume a container of content packs
                }
            }
        }
        final dirItems:Array<String> = FileSystem.readDirectory(contentDir);
        iterateThruContent(dirItems);

        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders.copy();
        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            Paths.unregisterAssetLoader(loader.id);
        }
        Paths.registerAssetLoader("default", new DefaultAssetLoader());

        final metaPath:String = Paths.json("metadata", "default", false);
        if(FlxG.assets.exists(metaPath)) {
            final parser:JsonParser<ContentMetadata> = new JsonParser<ContentMetadata>();
            parser.ignoreUnknownVariables = true;

            final meta:ContentMetadata = parser.fromJson(FlxG.assets.getText(metaPath));
            meta.folder = "assets";

            for(level in meta.levels)
                level.mixes.insert(0, "default");

            meta.id = "default";

            contentPacksToFolders.set(meta.id, meta.folder);
            contentFoldersToPacks.set(meta.folder, meta.id);

            contentMetadata.set(meta.id, meta);
        }
        final contentDir:String = getContentDirectory();
        for(i in 0...contentFolders.length) {
            final folder:String = contentFolders[i];
            final shortFolder:String = folder.substr(folder.lastIndexOf("/") + 1);

            final metaPath:String = '${contentDir}/${folder}/metadata.json';
            if(FlxG.assets.exists(metaPath)) {
                final parser:JsonParser<ContentMetadata> = new JsonParser<ContentMetadata>();
                parser.ignoreUnknownVariables = true;

                final meta:ContentMetadata = parser.fromJson(FlxG.assets.getText(metaPath));
                meta.folder = folder;

                for(level in meta.levels)
                    level.mixes.insert(0, "default");

                if(meta.id == null || meta.id.length == 0)
                    meta.id = shortFolder;

                contentPacks.push(meta.id);

                contentPacksToFolders.set(meta.id, folder);
                contentFoldersToPacks.set(folder, meta.id);

                contentMetadata.set(meta.id, meta);
            } else {
                contentPacks.push(shortFolder);

                contentPacksToFolders.set(shortFolder, folder);
                contentFoldersToPacks.set(folder, shortFolder);
            }
        }
        // clear out non-existent content packs from save data
        final packs:Array<String> = cast Options.contentPackOrder;
        if(packs.length != 0) {
            for(i in 0...packs.length) {
                final pack:String = packs[i];
                if(!contentPacks.contains(pack)) {
                    packs.remove(pack);
                    Options.toggledContentPacks.remove(pack);
                }
            }
        }
        // add any new content packs to save data
        for(i in 0...contentPacks.length) {
            final pack:String = contentPacks[i];
            if(packs.contains(pack))
                continue;

            packs.push(pack);
            Options.toggledContentPacks.set(pack, true);
        }
        // remove duplicates from the list
        // and clear custom option pages
        Options.contentPackOrder = packs.removeDuplicates();

        Options.customPages.clear();
        Options.customOptionConfigs.clear();
        
        // register the content packs in the correct order (and if they're enabled)
        final packs:Array<String> = cast Options.contentPackOrder;
        for(i in 0...packs.length) {
            final pack:String = packs[i];
            if(Options.toggledContentPacks.get(pack)) {
                // register me that yummy asset loader 😋
                final loader:ContentAssetLoader = new ContentAssetLoader(contentPacksToFolders.get(pack));
                registerAssetLoader(pack, loader);

                // init any new options for this content pack
                final jsonPath:String = Paths.json("options", pack, false);
                if(FlxG.assets.exists(jsonPath)) {
                    final parser:JsonParser<CustomOptionsData> = new JsonParser<CustomOptionsData>();
                    parser.ignoreUnknownVariables = true;
    
                    final optionsData:CustomOptionsData = parser.fromJson(FlxG.assets.getText(jsonPath));
                    Options.customPages.set(pack, optionsData.pages);

                    var map:Map<String, Dynamic> = Options.customOptions.get(pack);
                    if(map == null)
                        map = new Map<String, Dynamic>();
                    
                    var arr:Array<CustomOption> = Options.customOptionConfigs.get(pack);
                    if(arr == null)
                        arr = new Array<CustomOption>();
                    
                    for(option in optionsData.options) {
                        final config:CustomOption = {
                            name: option.name,
                            description: option.description,

                            id: '${pack}://${option.id}',
                            defaultValue: option.defaultValue,

                            type: option.type,
                            params: option.params,

                            page: option.page,
                            showInMenu: option.showInMenu
                        };
                        arr.push(config);
                        
                        if(map.get(option.id) == null)
                            map.set(option.id, option.defaultValue);
                    }
                    Options.customOptions.set(pack, map);
                    Options.customOptionConfigs.set(pack, arr);
                }
            }
        }
    }

    public static function getEnabledContentPacks():Array<String> {
        final enabledPacks:Array<String> = [];
        final allPacks:Array<String> = cast Options.contentPackOrder;
    
        for(pack in allPacks) {
            if(Options.toggledContentPacks.get(pack))
                enabledPacks.push(pack);
        }
        return enabledPacks;
    }

    public static function sanitizePath(path:String):String {
        var sanitizedPath:String = Path.normalize(path);
        #if LINUX_CASE_INSENSITIVE_FILES
        sanitizedPath = _getPathLike(sanitizedPath); // handles case-insensitive files
        #end
        return sanitizedPath;
    }

    public static function getAsset(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        if(loaderID == null || loaderID.length == 0)
            loaderID = Paths.forceContentPack;

        if(loaderID == null || loaderID.length == 0) {
            final loaders:Array<AssetLoader> = _registeredAssetLoaders;
            for(i in 0...loaders.length) {
                var path:String = sanitizePath(loaders[i].getPath(name));
                if(FlxG.assets.exists(path))
                    return path;
            }
        } else {
            // try to load from specified loader id (usually the name of a content pack)
            final loader:AssetLoader = _registeredAssetLoadersMap.get(loaderID);
            if(loader != null) {
                final path:String = sanitizePath(loader.getPath(name));
                if(FlxG.assets.exists(path))
                    return path;
    
                if(useFallback) {
                    // load from loaders that have runGlobally set as true
                    // inside of their metadata as fallback
                    final loaders:Array<AssetLoader> = _registeredAssetLoaders;
                    for(i in 0...loaders.length) {
                        final contentMetadata:ContentMetadata = contentMetadata.get(loaders[i].id);
                        if(contentMetadata != null && !contentMetadata.runGlobally && Paths.forceContentPack != loaders[i].id)
                            continue;
        
                        final path:String = sanitizePath(loaders[i].getPath(name));
                        if(FlxG.assets.exists(path))
                            return path;
                    }
                }
            }
        }
        // either use assets as emergency fallback (usually enabled)
        // or return null
        if(useFallback) {
            final liveReload:Bool = #if TEST_BUILD true #else Sys.args().contains("-livereload") #end;
            return '${(liveReload) ? "../../../../" : ""}assets/${name}';
        }
        return null;
    }

    public static function image(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(IMAGE);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID, useFallback);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.png', loaderID, useFallback);
    }

    public static function sound(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(SOUND);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID, useFallback);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.ogg', loaderID, useFallback);
    }

    public static function video(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(VIDEO);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID, useFallback);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.mp4', loaderID, useFallback);
    }

    public static function font(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(FONT);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID, useFallback);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.ttf', loaderID, useFallback);
    }

    public static function json(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.json', loaderID, useFallback);
    }

    public static function xml(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.xml', loaderID, useFallback);
    }

    public static function txt(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.txt', loaderID, useFallback);
    }

    public static function csv(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.csv', loaderID, useFallback);
    }

    public static function frag(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.frag', loaderID, useFallback);
    }

    public static function vert(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        return getAsset('${name}.vert', loaderID, useFallback);
    }

    public static function script(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(SCRIPT);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID, useFallback);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.hx', loaderID, useFallback);
    }

    public static function isAssetType(path:String, type:AssetType):Bool {
        final exts:Array<String> = ASSET_EXTENSIONS.get(type);
        for(i in 0...exts.length) {
            if(path.endsWith(exts[i]))
                return true;
        }
        return false;
    }

    public static function getSparrowAtlas(name:String, ?loaderID:String, ?useFallback:Bool = true):FlxAtlasFrames {
        final imgPath:String = image(name, loaderID, useFallback);
        final xmlPath:String = xml(name, loaderID, useFallback);

        final key:String = 'SPARROW://${imgPath}:${xmlPath}';
        if(Cache.atlasCache.get(key) == null) {
            final atlas:FlxAtlasFrames = FlxAtlasFrames.fromSparrow(imgPath, xmlPath);
            if(atlas.parent != null) {
                atlas.parent.persist = true;
                atlas.parent.incrementUseCount();
            }
            Cache.atlasCache.set(key, atlas);
        }
        return cast Cache.atlasCache.get(key);
    }

    public static function getAnimateAtlas(name:String, ?loaderID:String, ?useFallback:Bool = true):FlxAtlasFrames {
        final basePath:String = getAsset(name, loaderID, useFallback);
        final key:String = 'ANIMATE_TA://${basePath}';
        
        if(Cache.atlasCache.get(key) == null) {
            final atlas:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(basePath);
            if(atlas.parent != null) {
                atlas.parent.persist = true;
                atlas.parent.incrementUseCount();
            }
            Cache.atlasCache.set(key, atlas);
        }
        return cast Cache.atlasCache.get(key);
    }

    public static function iterateDirectory(dir:String, callback:String->Void, ?recursive:Bool = false):Void {
        for(loader in _registeredAssetLoaders) {
            final dirPath:String = sanitizePath(loader.getPath(dir));
            if(!FileSystem.exists(dirPath))
                continue;
            
            for(item in FileSystem.readDirectory(dirPath)) {
                final itemPath:String = '${dirPath}/${item}';
                if(recursive && FileSystem.isDirectory(itemPath))
                    iterateDirectory(itemPath, callback, true);
                else
                    callback(itemPath);
            }
        }
    }

    public static function isDirectory(path:String):Bool {
        return FileSystem.isDirectory(path);
    }

    public static function withoutDirectory(path:String):String {
        return Path.withoutDirectory(path);
    }

    public static function withoutExtension(path:String):String {
        return Path.withoutExtension(path);
    }

    public static function getContentFolderFromPath(path:String, ?includeContainerFolders:Bool = false):String {
        final contentDir:String = getContentDirectory();
        path = path.replace("\\", "/"); // go fuck yourself windows

        for(rawContentFolder in Paths.contentFolders) {
            if(path.startsWith('${contentDir}/${rawContentFolder}/'))
                return (!includeContainerFolders) ? rawContentFolder.substr(rawContentFolder.lastIndexOf("/") + 1) : rawContentFolder;
        }
        return "default";
    }

    public static function getContentPackFromPath(path:String):String {
        return contentFoldersToPacks.get(getContentFolderFromPath(path, true));
    }

    //----------- [ Private API ] -----------//
    
    @:unreflective
    private static var _registeredAssetLoaders:Array<AssetLoader> = [];

    @:unreflective
    private static var _registeredAssetLoadersMap:Map<String, AssetLoader> = [];

    @:unreflective
    private static function get_registeredAssetLoaders():ReadOnlyArray<AssetLoader> {
        return cast _registeredAssetLoaders.copy();
    }
    
    #if LINUX_CASE_INSENSITIVE_FILES
    // Case-insensitive files on Linux builds
    
    // Windows and macOS both have case-sensitive files by default already,
    // hence the linux specific define

    // Original code is from Polymod: https://github.com/larsiusprime/polymod/blob/experimental/polymod/fs/SysFileSystem.hx#L172

    /**
    * Returns a path to the existing file similar to the given one.
    * (For instance "mod/lasagnaday" and  "Mod/LasagnaDay" are *similar* paths)
    *
    * @param path
    */
    private static function _getPathLike(path:String):Null<String> {
        if(FlxG.assets.exists(path))
            return path;
        
        final baseParts:Array<String> = path.replace('\\', '/').split('/');
        if(baseParts.length == 0)
            return null;
        
        final keyParts:Array<String> = [];
        while(!FlxG.assets.exists(baseParts.join("/")) && baseParts.length != 0)
            keyParts.insert(0, baseParts.pop());
        
        return _findFile(baseParts.join("/"), keyParts);
    }

    private static function _findFile(basePath:String, keys:Array<String>):Null<String> {
        var nextDir:String = basePath;
        for(part in keys) {
            if(part == '')
                continue;
            
            final foundNode = _findNode(nextDir, part);
            if(foundNode == null)
                return null;
            
            nextDir += '/${foundNode}';
        }	return nextDir;
    }

    /**
    * Searches a given directory and returns a name of the existing file/directory
    * *similar* to the **key**
    * 
    * @param dir Base directory to search
    * @param key The file/directory you want to find
    * 
    * @return Either a file name, or null if the file doesn't exist
    */
    private static function _findNode(dir:String, key:String):Null<String> {
        try {
            final allFiles:Array<String> = FileSystem.readDirectory(dir);
            
            final fileMap:Map<String, String> = [];
            for(file in allFiles)
                fileMap.set(file.toLowerCase(), file);
            
            return fileMap.get(key.toLowerCase());
        }
        catch(e:Dynamic) {
            return null;
        }
    }
    #end
}