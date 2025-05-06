package funkin.gameplay.events;

import funkin.backend.ContentMetadata;
import funkin.backend.events.GameplayEvents;
import funkin.backend.assets.loaders.AssetLoader;

import funkin.scripting.FunkinScript;
import funkin.scripting.FunkinScriptGroup;

import funkin.states.PlayState;

class EventBehavior {
    public var game(default, null):PlayState;
    public var eventType(default, null):String;
    public var scripts(default, null):FunkinScriptGroup;

    public function new(eventType:String) {
        game = PlayState.instance;
        this.eventType = eventType;

        #if SCRIPTING_ALLOWED
        if(game.scriptsAllowed) {
            scripts = new FunkinScriptGroup();
            scripts.setParent(game);
    
            @:privateAccess
            final loaders:Array<AssetLoader> = Paths._registeredAssetLoaders;
            for(i in 0...loaders.length) {
                final loader:AssetLoader = loaders[i];
                final contentMetadata:ContentMetadata = Paths.contentMetadata.get(loader.id);
    
                if(Paths.forceContentPack != loader.id && !(contentMetadata?.runGlobally ?? true))
                    continue;
    
                final scriptPath:String = Paths.script('gameplay/events/${eventType}', loader.id, false);
                if(FlxG.assets.exists(scriptPath)) {
                    final script:FunkinScript = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
                    script.set("isCurrentPack", () -> return Paths.forceContentPack == loader.id);
                    scripts.add(script);
                }
            }
        }
        #end
    }

    public function execute(e:SongEvent):Void {
        #if SCRIPTING_ALLOWED
        if(game.scriptsAllowed)
            scripts.call("onExecute", [e]);
        #end
    }

    public function destroy():Void {
        #if SCRIPTING_ALLOWED
        if(game.scriptsAllowed) {
            scripts.call("onDestroy");
            scripts.close();
            scripts = null;
        }
        #end
    }
}