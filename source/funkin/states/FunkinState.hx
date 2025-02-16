package funkin.states;

import funkin.backend.Controls;
import funkin.backend.interfaces.IBeatReceiver;

class FunkinState extends FlxState implements IBeatReceiver {
    public var controls(get, never):Controls;

    public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}

    @:noCompletion
    private inline function get_controls():Controls {
        return Controls.instance;
    }
}