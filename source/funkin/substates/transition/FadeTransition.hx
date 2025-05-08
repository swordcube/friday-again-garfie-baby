package funkin.substates.transition;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;

import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

class FadeTransition extends TransitionSubState {
    public static var defaultCamera:FlxCamera;
	public static var nextCamera:FlxCamera;
    
	public var curStatus:TransitionStatus;
    
	public var gradient:FlxSprite;
	public var gradientFill:FlxSprite;
    
	public var updateFunc:Null<Void->Void> = null;

	override function start(status:TransitionStatus):Void {
		var cam = (nextCamera != null) ? nextCamera : ((defaultCamera != null) ? defaultCamera : FlxG.cameras.list[FlxG.cameras.list.length - 1]);
		cameras = [cam];

		nextCamera = null;
		curStatus = status;

		var duration:Float = .48;
		var angle:Int = 90;
		var zoom:Float = FlxMath.bound(cam.zoom, 0.001);
		var width:Int = Math.ceil(cam.width / zoom);
		var height:Int = Math.ceil(cam.height / zoom);
		var yStart = -height;
		var yEnd = height;

		switch (status) {
			case IN:
				updateFunc = () -> gradientFill.y = gradient.y - gradient.height;
            
			case OUT:
				angle = 270;
				updateFunc = () -> gradientFill.y = gradient.y + gradient.height;
				duration = 0.6;
			
            default:
		}
		gradient = FlxGradient.createGradientFlxSprite(width, height, [FlxColor.BLACK, FlxColor.TRANSPARENT], 1, angle);
		gradient.scrollFactor.set();
		gradient.screenCenter(X);
		gradient.y = yStart;

		gradientFill = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
		gradientFill.scrollFactor.set();
		gradientFill.screenCenter(X);
		updateFunc();

		add(gradientFill);
		add(gradient);

		FlxTween.tween(gradient, {y: yEnd}, duration, {onComplete: (_) -> {
			delayThenFinish();
		}});
	}

	override function update(elapsed:Float) {
		if(updateFunc != null)
			updateFunc();

		if(FlxG.keys.pressed.SHIFT)
			delayThenFinish();

		super.update(elapsed);
	}

    //----------- [ Private API ] -----------//

    private var _finalDelayTime:Float = 0.0;

	private function delayThenFinish():Void {
		new FlxTimer().start(_finalDelayTime, onFinish); // force one last render call before exiting
	}

	private function onFinish(f:FlxTimer):Void {
		if(finishCallback != null) {
			finishCallback();
			finishCallback = null;
		}
	}

	override function destroy():Void {
		super.destroy();

		if(gradient != null)
			gradient.destroy();
        
		if(gradientFill != null)
			gradientFill.destroy();
        
        gradient = null;
		gradientFill = null;
		finishCallback = null;
	}
}
