package funkin.assets;

import haxe.io.Path;
import flixel.graphics.frames.FlxAtlasFrames;
import sys.io.File;
import sys.FileSystem;

import openfl.text.Font;
import openfl.media.Sound;
import openfl.display.BitmapData;

import flixel.system.frontEnds.AssetFrontEnd;

import haxe.ds.ReadOnlyArray;
import funkin.assets.loaders.AssetLoader;

enum AssetType {
    IMAGE;
    SOUND;
    FONT;
    JSON;
    XML;
    SCRIPT;
}

@:allow(funkin.backend.ModManager)
class Paths {
    public static final ASSET_EXTENSIONS:Map<AssetType, Array<String>> = [
        IMAGE => [".png", ".jpg", ".jpeg", ".bmp"],
        SOUND => [".ogg", ".wav", ".mp3"],
        FONT => [".ttf", ".otf"],
        SCRIPT => [".hx", ".hxs", ".hsc", ".hscript", ".lua"]
    ];
    public static var forceMod:String = null;

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

    public static function getAsset(name:String, ?loaderID:String):String {
        if(loaderID == null || loaderID.length == 0)
            loaderID = Paths.forceMod;

        if(loaderID == null || loaderID.length == 0) {
            final loaders:Array<AssetLoader> = _registeredAssetLoaders;
            for(i in 0...loaders.length) {
                final path:String = loaders[i].getPath(name);
                if(FlxG.assets.exists(path))
                    return path;
            }
        } else {
            final loader:AssetLoader = _registeredAssetLoadersMap.get(loaderID);
            final path:String = loader.getPath(name);
            if(loader != null && FlxG.assets.exists(path))
                return path;
        }
        return 'assets/${name}';
    }

    public static function image(name:String, ?loaderID:String):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(IMAGE);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.png');
    }

    public static function sound(name:String, ?loaderID:String):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(SOUND);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.ogg');
    }

    public static function font(name:String, ?loaderID:String):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(FONT);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.ttf', loaderID);
    }

    public static function json(name:String, ?loaderID:String):String {
        return getAsset('${name}.json', loaderID);
    }

    public static function xml(name:String, ?loaderID:String):String {
        return getAsset('${name}.xml', loaderID);
    }

    public static function txt(name:String, ?loaderID:String):String {
        return getAsset('${name}.txt', loaderID);
    }

    public static function script(name:String, ?loaderID:String):String {
        final exts:Array<String> = ASSET_EXTENSIONS.get(SCRIPT);
        for(i in 0...exts.length) {
            final path:String = getAsset('${name}${exts[i]}', loaderID);
            if(FlxG.assets.exists(path))
                return path;
        }
        return getAsset('${name}.hx');
    }

    public static function getSparrowAtlas(name:String, ?loaderID:String):FlxAtlasFrames {
        if(Cache.atlasCache.get(name) == null) {
            final atlas:FlxAtlasFrames = FlxAtlasFrames.fromSparrow(
                image(name, loaderID),
                xml(name, loaderID)
            );
            if(atlas.parent != null) {
                atlas.parent.persist = true;
                atlas.parent.destroyOnNoUse = false;
                atlas.parent.incrementUseCount();
            }
            Cache.atlasCache.set(name, atlas);
        }
        return cast Cache.atlasCache.get(name);
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