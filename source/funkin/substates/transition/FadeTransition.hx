package funkin.substates.transition;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;

import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;

class FadeTransition extends TransitionSubState {
	public var curStatus:TransitionStatus;
    
	public var gradient:FlxSprite;
	public var gradientFill:FlxSprite;
    
	public var updateFunc:Null<Void->Void> = null;

	override function start(status:TransitionStatus):Void {
		var cam = (TransitionSubState.nextCamera != null) ? TransitionSubState.nextCamera : ((TransitionSubState.defaultCamera != null) ? TransitionSubState.defaultCamera : FlxG.cameras.list[FlxG.cameras.list.length - 1]);
		cameras = [cam];

		TransitionSubState.nextCamera = null;
		curStatus = status;

		var duration:Float = .48;
		var angle:Int = 90;
		var zoom:Float = FlxMath.bound(cam.zoom, 0.001);
		var width:Int = Math.ceil(cam.width / zoom) * 4;
		var height:Int = Math.ceil(cam.height / zoom);
		var yStart = -height;
		var yEnd = height;

		switch (status) {
			case IN:
				angle = 270;
				updateFunc = () -> gradientFill.y = gradient.y + gradient.height;
				duration = 0.6;
				
			case OUT:
				updateFunc = () -> gradientFill.y = gradient.y - gradient.height;
			
            default:
		}
		gradient = FlxGradient.createGradientFlxSprite(1, height, [FlxColor.BLACK, FlxColor.TRANSPARENT], 1, angle);
		gradient.scrollFactor.set();
		gradient.setGraphicSize(width, height);
		gradient.updateHitbox();
		gradient.screenCenter(X);
		gradient.y = yStart;

		gradientFill = new FlxSprite().makeSolid(width, height, FlxColor.BLACK);
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
