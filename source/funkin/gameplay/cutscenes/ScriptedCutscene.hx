package funkin.gameplay.cutscenes;

#if SCRIPTING_ALLOWED
import funkin.states.PlayState;
import funkin.scripting.FunkinScript;

class ScriptedCutscene extends Cutscene {
    public var script:FunkinScript;
    public var scriptPath:String;

    public function new(name:String) {
        super();
        final game:PlayState = PlayState.instance;

        script = FunkinScript.fromFile(scriptPath ?? Paths.script('gameplay/cutscenes/${name}'));
        script.setParent(this);
        script.execute();
        script.call("new");

        if(game != null) {
            game.scripts.add(script);
            script.setParent(this);
        }
        onFinish.add(_finishCallback);
    }

    override function start():Void {
        super.start();
        script.call("onStart");
    }

    // onPause and onResume get called for all gameplay scripts
    // and scripted cutscenes count as those so this isn't needed actually, oops!
    
    // override function pause():Void {
    //     super.pause();
    //     script.call("onPause");
    // }

    // override function resume():Void {
    //     super.pause();
    //     script.call("onResume");
    // }

    override function restart():Void {
        super.restart();
        script.call("onRestart");
    }

    private function _finishCallback():Void {
        script.call("onFinish");
    }

    override function destroy():Void {
        if(!script.closed) {
            script.call("onDestroy");
            script.close();
            script = null;
        }
        onFinish.remove(_finishCallback);
        super.destroy();
    }
}
#end