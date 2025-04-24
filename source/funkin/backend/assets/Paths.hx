package funkin.backend.assets;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.frontEnds.AssetFrontEnd;
import funkin.backend.ContentMetadata;
import funkin.backend.WeekData;
import funkin.backend.assets.loaders.AssetLoader;
import funkin.backend.assets.loaders.ContentAssetLoader;
import funkin.backend.assets.loaders.DefaultAssetLoader;
import haxe.ds.ReadOnlyArray;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import sys.FileSystem;
import sys.io.File;

enum AssetType {
    IMAGE;
    SOUND;
    FONT;
    JSON;
    XML;
    SCRIPT;
}

#if SCRIPTING_ALLOWED
@:allow(funkin.scripting.GlobalScript)
#end
@:allow(funkin.backend.WeekData)
class Paths {
    public static final ASSET_EXTENSIONS:Map<AssetType, Array<String>> = [
        IMAGE => [".png", ".jpg", ".jpeg", ".bmp"],
        SOUND => [".ogg", ".wav", ".mp3"],
        FONT => [".ttf", ".otf"],
        SCRIPT => [".hx", ".hxs", ".hsc", ".hscript", ".lua"]
    ];
    public static final CONTENT_DIRECTORY:String = "content";

    public static var forceContentPack:String = null;

    public static var contentFolders:Array<String> = [];
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
        _registeredAssetLoaders.insert(priority, loader);
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
        contentMetadata.clear();

        final contentDir:String = getContentDirectory();
        final dirItems:Array<String> = FileSystem.readDirectory(contentDir);

        for(i in 0...dirItems.length) {
            final item:String = dirItems[i];
            if(!FileSystem.isDirectory('${contentDir}/${item}'))
                continue;
            
            contentFolders.push(item);
        }
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
            contentMetadata.set("default", meta);
        }
        for(i in 0...contentFolders.length) {
            final folder:String = contentFolders[i];
            Paths.registerAssetLoader(folder, new ContentAssetLoader(folder));

            final metaPath:String = Paths.json("metadata", folder, false);
            if(FlxG.assets.exists(metaPath)) {
                final parser:JsonParser<ContentMetadata> = new JsonParser<ContentMetadata>();
                parser.ignoreUnknownVariables = true;

                final meta:ContentMetadata = parser.fromJson(FlxG.assets.getText(metaPath));
                meta.folder = folder;
                contentMetadata.set(folder, meta);
            }
        }
    }

    public static function getAsset(name:String, ?loaderID:String, ?useFallback:Bool = true):String {
        if(loaderID == null || loaderID.length == 0)
            loaderID = Paths.forceContentPack;

        if(loaderID == null || loaderID.length == 0) {
            final loaders:Array<AssetLoader> = _registeredAssetLoaders;
            for(i in 0...loaders.length) {
                final path:String = loaders[i].getPath(name);
                if(FlxG.assets.exists(path))
                    return path;
            }
        } else {
            // try to load from specified loader id (usually the name of a content pack)
            final loader:AssetLoader = _registeredAssetLoadersMap.get(loaderID);
            if(loader != null) {
                final path:String = loader.getPath(name);
                if(FlxG.assets.exists(path))
                    return path;
    
                if(useFallback) {
                    // load from loaders that have runGlobally set as true
                    // inside of their metadata as fallback
                    final loaders:Array<AssetLoader> = _registeredAssetLoaders;
                    for(i in 0...loaders.length) {
                        final contentMetadata:ContentMetadata = contentMetadata.get(loaders[i].id);
                        if(contentMetadata != null && !contentMetadata.runGlobally)
                            continue;
        
                        final path:String = loaders[i].getPath(name);
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

        final key:String = '${imgPath}:${xmlPath}';
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

    public static function iterateDirectory(dir:String, callback:String->Void, ?recursive:Bool = false):Void {
        for(loader in _registeredAssetLoaders) {
            final dirPath:String = loader.getPath(dir);
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

    public static function getContentPackFromPath(path:String):String {
        final contentDir:String = getContentDirectory();
        path = path.replace("\\", "/"); // go fuck yourself windows

        if(path.startsWith('${contentDir}/')) {
            final split:Array<String> = path.substr(contentDir.length + 1).split("/");
            if(split.length > 0)
                return split.first();
        }
        return "default";
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
}