package funkin.gameplay.hud;

#if SCRIPTING_ALLOWED
import funkin.scripting.FunkinScript;
import funkin.states.PlayState;

class ScriptedHUD extends BaseHUD {
    public var skin(default, null):String;
    public var script(default, null):FunkinScript;

    public function new(playField:PlayField, skin:String) {
        this.skin = skin;

        final scriptPath:String = Paths.script('gameplay/hudskins/${skin}/script');
        final contentMetadata = Paths.contentMetadata.get(Paths.getContentPackFromPath(scriptPath));
        
        script = FunkinScript.fromFile(scriptPath, contentMetadata?.allowUnsafeScripts ?? false);
        script.setParent(this);
        script.set("getHUDImage", (name:String) -> {
            return Paths.image('gameplay/hudskins/${skin}/images/${name}');
        });
        script.execute();
        script.call("onLoad");
        
        super(playField);
        script.call("onLoadPost");
    }

    override function call(method:String, ?args:Array<Dynamic>):Void {
        super.call(method, args);

        final game:PlayState = PlayState.instance;
        if(game == null) // script will be called onto by PlayState already, so skip if we're in PlayState
            script.call(method, args);
    }

    override function generateHealthBar():Void {
        script.call("generateHealthBar");
    }
    
    override function generatePlayerStats():Void {
        script.call("generatePlayerStats");
    }
    
    override function updateHealthBar():Void {
        script.call("updateHealthBar");
    }

    override function updatePlayerStats(stats:PlayerStats):Void {
        script.call("updatePlayerStats", [stats]);
    }

    override function bopIcons():Void {
        script.call("bopIcons");
    }

    override function positionIcons():Void {
        script.call("positionIcons");
    }

    override function stepHit(step:Int):Void {
        script.call("stepHit", [step]);
    }

    override function beatHit(beat:Int):Void {
        if(beat >= 0)
            bopIcons();
        
        script.call("beatHit", [beat]);
    }

    override function measureHit(measure:Int):Void {
        script.call("measureHit", [measure]);
    }

    override function destroy() {
        script.close();
        super.destroy();
    }
}
#end