package funkin.backend.scripting;

#if SCRIPTING_ALLOWED
import funkin.backend.assets.loaders.AssetLoader;
import funkin.backend.assets.loaders.ContentAssetLoader;
import funkin.backend.assets.loaders.DefaultAssetLoader;
import funkin.backend.scripting.FunkinScript;
import funkin.backend.scripting.FunkinScriptGroup;

class GlobalScript {
	public static var scripts(default, null):FunkinScriptGroup;
	
    /**
	 * Initializes some callbacks for global scripts.
     */
	public static function init():Void {
        scripts = new FunkinScriptGroup();
		
        FlxG.signals.focusGained.add(() -> {
			scripts.call("onFocusGained");
		});
		FlxG.signals.focusLost.add(() -> {
			scripts.call("onFocusLost");
		});
		FlxG.signals.gameResized.add((w:Int, h:Int) -> {
			scripts.call("onGameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(() -> {
			scripts.call("onDrawPost");
		});
		FlxG.signals.postGameReset.add(() -> {
			scripts.call("onGameResetPost");
		});
		FlxG.signals.postGameStart.add(() -> {
			scripts.call("onGameStartPost");
		});
		FlxG.signals.postStateSwitch.add(() -> {
			scripts.call("onStateSwitchPost");
		});
		FlxG.signals.postUpdate.add(() -> {
			scripts.call("onUpdatePost", [FlxG.elapsed]);
        });
        FlxG.signals.preDraw.add(() -> {
			scripts.call("onDraw");
		});
		FlxG.signals.preGameReset.add(() -> {
			scripts.call("onGameReset");
		});
		FlxG.signals.preGameStart.add(() -> {
			scripts.call("onGameStart");
		});
		FlxG.signals.preStateCreate.add(function(state:FlxState) {
			scripts.call("onStateCreate", [state]);
		});
		FlxG.signals.preStateSwitch.add(() -> {
			scripts.call("onStateSwitch", []);
		});
		FlxG.signals.preUpdate.add(() -> {
			scripts.call("onUpdate", [FlxG.elapsed]);
		});
		reloadScripts();
    }
	
    public static function reloadScripts():Void {
		scripts.close(); // this just closes the scripts, doesn't de-init the script group
		WindowUtil.resetTitle(); // reset window title, incase a global script changes it
		
        for(i in 0...Paths._registeredAssetLoaders.length) {
			// go thru all asset loaders
            final loader:AssetLoader = Paths._registeredAssetLoaders[i];

			// the extra false is to prevent this falling back to assets/global.hxs
			// which would effectively load the main global script for as many content packs
			// as there are that don't have a global script
            final globalScriptPath:String = Paths.script("global", loader.id, false);
			
            if(FlxG.assets.exists(globalScriptPath)) {
                // if global script for this asset loader exists, load it
                final script:FunkinScript = FunkinScript.fromFile(globalScriptPath);
                scripts.add(script);
            }
        }
        scripts.execute();
        scripts.call("new");
    }
}
#end