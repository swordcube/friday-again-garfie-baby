package funkin.substates.transition;

import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

class TransitionSubState extends FlxSubState {
	public static var defaultCamera:FlxCamera;
	public static var nextCamera:FlxCamera;
	
	public var finishCallback:Void->Void;

	override function destroy():Void {
		finishCallback = null;
		super.destroy();
	}

	public function start(status:TransitionStatus):Void {}
}