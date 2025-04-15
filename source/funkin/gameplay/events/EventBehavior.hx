package funkin.gameplay.events;

import funkin.backend.events.GameplayEvents;
import funkin.scripting.FunkinScript;
import funkin.states.PlayState;

class EventBehavior {
    public var game(default, null):PlayState;
    public var eventType(default, null):String;
    public var script(default, null):FunkinScript;

    public function new(eventType:String) {
        game = PlayState.instance;
        this.eventType = eventType;

        #if SCRIPTING_ALLOWED
        final scriptPath:String = Paths.script('gameplay/events/${eventType}');
        if(FlxG.assets.exists(scriptPath)) {
            final contentMetadata = Paths.contentMetadata.get(Paths.getContentPackFromPath(scriptPath));
            script = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);

            script.setParent(game);
            script.execute();
            script.call("onCreate");
        }
        #end
    }

    public function execute(e:SongEvent):Void {
        #if SCRIPTING_ALLOWED
        if(script != null)
            script.call("onExecute", [e]);
        #end
    }

    public function destroy():Void {
        #if SCRIPTING_ALLOWED
        if(script != null) {
            script.call("onDestroy");
            script.close();
            script = null;
        }
        #end
    }
}