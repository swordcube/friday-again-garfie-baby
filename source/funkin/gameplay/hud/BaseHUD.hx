package funkin.gameplay.hud;

import funkin.backend.interfaces.IBeatReceiver;

class BaseHUD extends FlxGroup implements IBeatReceiver {
    public function new() {
        super();
        
        generateHealthBar();
        updateHealthBar();

        generatePlayerStats();
        updatePlayerStats();
    }

    public function generateHealthBar():Void {}
    public function generatePlayerStats():Void {}
    
    public function updateHealthBar():Void {}
    public function updatePlayerStats():Void {}

    public function stepHit(step:Int) {}
    public function beatHit(beat:Int) {}
    public function measureHit(measure:Int) {}
}