package funkin.backend;

import sys.io.File;
import sys.FileSystem;

import haxe.ds.ReadOnlyArray;
import funkin.assets.loaders.AssetLoader;

import funkin.assets.loaders.DefaultAssetLoader;
import funkin.assets.loaders.ModAssetLoader;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinScript;
#end

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

    #if SCRIPTING_ALLOWED
    public static var globalScripts(get, never):ReadOnlyArray<FunkinScript>;
    #end

    /**
     * Initializes some callbacks for global scripts.
     */
    public static function init():Void {
        #if SCRIPTING_ALLOWED
        FlxG.signals.focusGained.add(() -> {
			callOnGlobalScripts("onFocusGained");
		});
		FlxG.signals.focusLost.add(() -> {
			callOnGlobalScripts("onFocusLost");
		});
		FlxG.signals.gameResized.add((w:Int, h:Int) -> {
			callOnGlobalScripts("onGameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(() -> {
			callOnGlobalScripts("onDrawPost");
		});
		FlxG.signals.postGameReset.add(() -> {
			callOnGlobalScripts("onGameResetPost");
		});
		FlxG.signals.postGameStart.add(() -> {
			callOnGlobalScripts("onGameStartPost");
		});
		FlxG.signals.postStateSwitch.add(() -> {
			callOnGlobalScripts("onStateSwitchPost");
		});
		FlxG.signals.postUpdate.add(() -> {
			callOnGlobalScripts("onUpdatePost", [FlxG.elapsed]);
        });
        FlxG.signals.preDraw.add(() -> {
			callOnGlobalScripts("onDraw");
		});
		FlxG.signals.preGameReset.add(() -> {
			callOnGlobalScripts("onGameReset");
		});
		FlxG.signals.preGameStart.add(() -> {
			callOnGlobalScripts("onGameStart");
		});
		FlxG.signals.preStateCreate.add(function(state:FlxState) {
			callOnGlobalScripts("onStateCreate", [state]);
		});
		FlxG.signals.preStateSwitch.add(() -> {
			callOnGlobalScripts("onStateSwitch", []);
		});
		FlxG.signals.preUpdate.add(() -> {
			callOnGlobalScripts("onUpdate", [FlxG.elapsed]);
		});
        #end

        // scan and register mods
        scanMods();
        registerMods();
    }
    
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

        #if SCRIPTING_ALLOWED
        Logs.verbose('Closing ${_globalScripts.length} global script${(_globalScripts.length == 1) ? "" : "s"}');
        for(script in _globalScripts) {
            script.call("onDestroy");
            script.close();
        }
        _globalScripts.clear();

        final path:String = Paths.script("global", "default");
        if(FlxG.assets.exists(path)) {
            Logs.verbose('Loading main global script');
            
            final script:FunkinScript = FunkinScript.fromFile(Paths.script("global", "default"));
            script.setClass(ModManager);
            script.set("mod", null);
            script.execute();
            
            script.call("new");
            _globalScripts.push(script);
        }
        #end
        
        final modFolders:Map<String, String> = _modFolders;
        for(i in 0..._scannedMods.length) {
            final modID:String = _scannedMods[i];
            Paths.registerAssetLoader(modFolders.get(modID), new ModAssetLoader(modID));
            
            #if SCRIPTING_ALLOWED
            final path:String = Paths.script("global", modFolders.get(modID));
            if(FlxG.assets.exists(path)) {
                Logs.verbose('Loading global script for mod: ${modID}');

                final script:FunkinScript = FunkinScript.fromFile(path);
                script.setClass(ModManager);
                script.set("mod", modID);
                script.execute();
    
                script.call("new");
                _globalScripts.push(script);
            }
            #end
        }
    }

    #if SCRIPTING_ALLOWED
    /**
     * Calls a function on all global scripts.
     * 
     * @param  func   The function to call.
     * @param  args   The arguments to pass to the function (optional).
     */
    public static function callOnGlobalScripts(func:String, ?args:Array<Dynamic>):Void {
        for(i in 0..._globalScripts.length) {
            final script:FunkinScript = _globalScripts[i];
            if(script == null)
                continue;

            script.call(func, args);
        }
    }
    #end

    //----------- [ Private API ] -----------//

    @:unreflective
    private static var _scannedMods:Array<String> = [];

    @:unreflective
    private static var _modFolders:Map<String, String> = [];

    #if SCRIPTING_ALLOWED
    @:unreflective
    private static var _globalScripts:Array<FunkinScript> = [];
    #end

    @:unreflective
    private static function get_scannedMods():ReadOnlyArray<String> {
        return cast _scannedMods.copy();
    }

    @:unreflective
    private static function get_modFolders():Map<String, String> {
        return cast _modFolders.copy();
    }

    #if SCRIPTING_ALLOWED
    @:unreflective
    private static function get_globalScripts():ReadOnlyArray<FunkinScript> {
        return cast _globalScripts.copy();
    }
    #end
}