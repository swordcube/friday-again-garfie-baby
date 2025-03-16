package funkin.substates;

import funkin.backend.Controls;
import funkin.backend.Conductor.IBeatReceiver;

class FunkinSubState extends FlxSubState implements IBeatReceiver {
    public var controls(get, never):Controls;

    public function stepHit(step:Int):Void {}
	public function beatHit(beat:Int):Void {}
	public function measureHit(measure:Int):Void {}

    @:noCompletion
    private inline function get_controls():Controls {
        return Controls.instance;
    }
}