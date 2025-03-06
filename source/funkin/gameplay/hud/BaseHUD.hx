package funkin.gameplay.hud;

import funkin.backend.Conductor.IBeatReceiver;

class BaseHUD extends FlxGroup implements IBeatReceiver {
    public var playField:PlayField;
    
    public var iconP2:HealthIcon;
    public var iconP1:HealthIcon;

    public function new(playField:PlayField) {
        super();
        this.playField = playField;
        
        generateHealthBar();
        updateHealthBar();

        generatePlayerStats();
        updatePlayerStats();
    }

    public function generateHealthBar():Void {}
    public function generatePlayerStats():Void {}
    
    public function updateHealthBar():Void {}
    public function positionIcons():Void {}
    public function updatePlayerStats():Void {}

    public function stepHit(step:Int) {}
    public function beatHit(beat:Int) {}
    public function measureHit(measure:Int) {}
}