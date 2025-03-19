package funkin.gameplay.hud;

#if SCRIPTING_ALLOWED
import funkin.backend.scripting.FunkinScript;

class ScriptedHUD extends BaseHUD {
    public var skin(default, null):String;
    public var script(default, null):FunkinScript;

    public function new(playField:PlayField, skin:String) {
        this.skin = skin;
        
        script = FunkinScript.fromFile(Paths.script('gameplay/hudskins/${skin}/script'));
        script.setParent(this);
        script.set("getHUDImage", (name:String) -> {
            return Paths.image('gameplay/hudskins/${this.skin}/images/${name}');
        });
        script.execute();
        
        super(playField);
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

    override function updatePlayerStats():Void {
        script.call("updatePlayerStats");
    }

    override function stepHit(step:Int) {
        script.call("stepHit", [step]);
    }

    override function beatHit(beat:Int) {
        script.call("beatHit", [beat]);
    }

    override function measureHit(measure:Int) {
        script.call("measureHit", [measure]);
    }

    override function destroy() {
        script.close();
        super.destroy();
    }
}
#end