package funkin.gameplay.events;

#if SCRIPTING_ALLOWED
import funkin.backend.events.GameplayEvents;

import funkin.scripting.FunkinScript;
import funkin.scripting.FunkinScriptGroup;

import funkin.gameplay.character.Character;

class ScriptCallBehavior extends EventBehavior {
    public function new() {
        super("Script Call");
    }

    override function execute(e:SongEvent) {
        super.execute(e);
        
        final params:ScriptCallParams = cast e.params;
        final scriptGroups:Array<FunkinScriptGroup> = [game.scripts];

        final args:Array<String> = params.args.split(',');
        for(group in scriptGroups) {
            group.call(params.method, args);
            if(group.publicVariables.exists(params.method)) {
                final func:Dynamic = group.publicVariables.get(params.method);
                if(func != null && Reflect.isFunction(func))
                    Reflect.callMethod(null, func, args);
            }
        }
        if(FunkinScript.staticVariables.exists(params.method)) {
            final func:Dynamic = FunkinScript.staticVariables.get(params.method);
            if(func != null && Reflect.isFunction(func))
                Reflect.callMethod(null, func, args);
        }
        final chars:Array<Character> = [game.spectator, game.opponent, game.player];
        for(char in chars) {
            if(char.script != null) {
                final func:Dynamic = char.script.get(params.method);
                if(func != null && Reflect.isFunction(func))
                    Reflect.callMethod(null, func, args);
            }
        }
        if(script != null)
            script.call("onExecutePost", [e.flagAsPost()]);
    }
}

typedef ScriptCallParams = {
    var method:String;
    var args:String;
}
#end