package funkin.backend;

import sys.io.File;
import sys.FileSystem;

import haxe.ds.ReadOnlyArray;
import funkin.assets.loaders.AssetLoader;

import funkin.assets.loaders.DefaultAssetLoader;
import funkin.assets.loaders.ModAssetLoader;

// TODO: mod ordering

typedef ModContributor = {
    var name:String;
    var icon:String;

    var desc:String;
    var roles:Array<String>;

    var url:String;
}

typedef ModVersionData = {
    var api:String;
    var mod:String;
}

typedef ModConfig = {
    var id:String;
    var name:String;

    var desc:String;
    var contributors:Array<ModContributor>;

    var versions:ModVersionData;
}

class ModManager {
    public static final MOD_DIRECTORY:String = "mods";

    public static var scannedMods(get, never):ReadOnlyArray<String>;
    public static var modFolders(get, never):Map<String, String>;

    /**
     * Updates the available list of mods by scanning
     * the mods folder for any mods with a valid configuration file.
     */
    public static function scanMods():Void {
        _scannedMods.clear();
        _modFolders.clear();

        final dirItems:Array<String> = FileSystem.readDirectory(MOD_DIRECTORY);
        for(i in 0...dirItems.length) {
            final item:String = dirItems[i];
            if(!FileSystem.isDirectory('${MOD_DIRECTORY}/${item}'))
                continue;

            var config:ModConfig = null;
            try {
                final parsedConfig:ModConfig = Json.parse(File.getContent('${MOD_DIRECTORY}/${item}/conf.json'));
                config = parsedConfig;

                if(config.id == null || config.id.length == 0)
                    throw "Mod ID is empty";

                if(config.versions == null || config.versions.api == null || config.versions.api.length == 0)
                    throw "Mod API version is empty";
            }
            catch(e) {
                FlxG.log.error('Failed to load mod config for "${item}": ${e}');
                config = null;
            }
            if(config == null)
                continue;

            _scannedMods.push(config.id);
            _modFolders.set(config.id, item);
        }
    }

    /**
     * Registers all available mods, allowing them to be used
     * for obtaining assets and such.
     * 
     * NOTE: You must run `scanMods()` before this function,
     * otherwise no mods will be registered!
     */
    public static function registerMods():Void {
        final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
        for(i in 0...loaders.length) {
            final loader:AssetLoader = loaders[i];
            Paths.unregisterAssetLoader(loader.id);
        }
        Paths.registerAssetLoader("default", new DefaultAssetLoader());

        final modFolders:Map<String, String> = _modFolders;
        for(i in 0..._scannedMods.length) {
            final modID:String = _scannedMods[i];
            Paths.registerAssetLoader(modFolders.get(modID), new ModAssetLoader(modID));
        }
    }

    //----------- [ Private API ] -----------//

    @:unreflective
    private static var _scannedMods:Array<String> = [];

    @:unreflective
    private static var _modFolders:Map<String, String> = [];

    @:unreflective
    private static function get_scannedMods():ReadOnlyArray<String> {
        return cast _scannedMods.copy();
    }

    @:unreflective
    private static function get_modFolders():Map<String, String> {
        return cast _modFolders.copy();
    }
}