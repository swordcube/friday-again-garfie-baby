package funkin.gameplay.modchart.events;

import flixel.tweens.FlxEase;

class EaseEvent extends ModEvent {
	public var endStep:Float = 0;
	public var startVal:Null<Float>;
	public var easeFunc:EaseFunction;
	public var length:Float = 0;

	public function new(manager:Manager, targetStep:Float, endStep:Float, modName:String, target:Float, easeFunc:EaseFunction, player:Int = 0, ?startVal:Float) {
		super(manager, targetStep, modName, target, player);

		this.endStep = endStep;
		this.easeFunc = easeFunc;
		this.startVal = startVal;

		length = endStep - targetStep;
	}

	function ease(e:EaseFunction, t:Float, b:Float, c:Float, d:Float) {
        // elapsed, begin, change (ending-beginning), duration
		final time = t / d;
		return c * e(time) + b;
	}

	override function execute(curStep:Float) {
		if(curStep <= endStep) {
			if(startVal == null)
				startVal = modifier.getValue(player);

			final passed = curStep - targetStep;
			final change = endVal - startVal;
			manager.setValue(modifier.getName(), ease(easeFunc, passed, startVal, change, length), player);
		}
        else if(curStep > endStep) {
			finished = true;
			manager.setValue(modifier.getName(), endVal, player);
		}
	}
}
