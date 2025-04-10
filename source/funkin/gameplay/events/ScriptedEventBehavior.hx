package funkin.gameplay.events;

import funkin.backend.scripting.events.gameplay.SongEvent;
import funkin.backend.scripting.FunkinScript;

class ScriptedEventBehavior extends EventBehavior {
    public var script(default, null):FunkinScript;

    public function new(eventType:String) {
        super(eventType);

        final scriptPath:String = Paths.script('gameplay/events/${eventType}');
        if(FlxG.assets.exists(scriptPath)) {
            script = FunkinScript.fromFile(scriptPath);
            script.setParent(game);
            script.execute();
            script.call("onCreate");
        }
    }

    override function execute(e:SongEvent):Void {
        if(script != null)
            script.call("onExecute", [e]);
    }
    
    override function destroy():Void {
        if(script != null) {
            script.call("onDestroy");
            script.close();
            script = null;
        }
        super.destroy();
    }
}