package funkin.gameplay.cutscenes;

import flixel.tweens.FlxEase;

class Timeline extends FlxBasic {
	public var frameRate(default, set):Float = 24;
	public var curFrame:Int = 0;
	public var actions:Array<TimelineAction> = [];

	var frameInterval = 1 / 24;
	var frameTimer:Float = 0;
	var totalTime:Float = 0;
	var actionIndex:Int = 0;

	public function new(?frameRate:Float = 24, ?frame:Int = 0) {
		super();
		this.frameRate = frameRate;
		this.curFrame = frame;
	}

	public function seek(frame:Int) { // Be careful when seeking
		curFrame = frame;

		for (i in 0...actions.length)
			actions[i].finished = false;
	}

	public function addAction(action:TimelineAction) {
		actions.push(action);
		actions.sort((a, b) -> Std.int(a.frame - b.frame));
	}

	public function playAnimation(frame:Int, obj:FlxSprite, anim:String):Void {
		addAction(new PlayAnimationAction(frame, obj, anim));
    }

	public function on(frame:Int, callback:Int->Null<Bool>):Void {
		addAction(new CallbackAction(frame, callback));
    }

	public function once(frame:Int, callback:Int->Void):Void {
		addAction(new CallbackAction(frame, (f:Int) -> {
			callback(f);
			return true;
		}));
    }

	public function until(startFrame:Int, endFrame:Int, callback:Int->Void):Void {
		addAction(new CallbackAction(startFrame, (f:Int) -> {
			callback(f);
			return f >= endFrame;
		}));
    }

	public function easeCallback(startFrame:Int, endFrame:Int, style:EaseFunction, callback:(Float, Float) -> Void):Void {
		addAction(new EaseCallbackAction(startFrame, endFrame, callback, style ?? FlxEase.linear));
    }

	public function easeProperties(startFrame:Int, endFrame:Int, style:EaseFunction, obj:Dynamic, properties:Dynamic, ?interval:Int):Void {
		addAction(new EasePropertiesAction(startFrame, endFrame, obj, properties, style ?? FlxEase.linear, interval));
    }

	public function secToFrame(s:Float):Int {
        return Math.floor(s / frameInterval);
    }
    
	public function frameToSec(f:Int):Float {
		return f * frameInterval;
    }

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		frameTimer += elapsed;
		totalTime += elapsed;

		var garbage:Array<TimelineAction> = [];
		while (frameTimer >= frameInterval) {
			curFrame++;
			// run the actions every timeline frame
			for (i in 0...actions.length) {
				var action:TimelineAction = actions[i];
				if (action.finished)
					continue;

				if (action.frame <= curFrame)
					action.execute(curFrame, totalTime);
				else
					break;
			}
			frameTimer -= frameInterval;
		}
	}

    //----------- [ Private API ] -----------//

    @:noCompletion
    private function set_frameRate(newValue:Float) {
		frameInterval = 1 / newValue;
		return frameRate = newValue;
	}
}

typedef EaseInfo = {
	var name:String;
	var value:Float;

	var ?startValue:Float;
	var ?range:Float;
}

class TimelineAction {
	public var frame:Int = 0;
	public var finished:Bool = false;

	public function new(frame:Int) {
		this.frame = frame;
	}

	public function execute(frame:Int, frameTime:Float):Void {}
}

class PlayAnimationAction extends TimelineAction {
	public var sprite:FlxSprite;
	public var name:String;

	public function new(frame:Int, sprite:FlxSprite, name:String) {
		super(frame);
		this.sprite = sprite;
		this.name = name;
	}

	override function execute(curFrame:Int, frameTime:Float):Void {
		// TODO: code to make sure it stays synced
		sprite.animation.play(name, true);
		finished = true;
	}
}

class CallbackAction extends TimelineAction {
	public var callback:Int->Null<Bool>;

	public function new(frame:Int, callback:Int->Null<Bool>) {
		super(frame);
		this.callback = callback;
	}

	override function execute(curFrame:Int, frameTime:Float):Void {
		finished = callback(curFrame) ?? false;
    }
}

class EasePropertiesAction extends TimelineAction {
	public var endFrame:Int = 0;
	public var obj:Dynamic;
	public var propertyInfo:Array<EaseInfo> = [];
	public var updateInterval:Int = 1;
	public var style:EaseFunction = FlxEase.quadOut;

	public var progress:Float = 0;

	var length:Int = 0;

	public function new(frame:Int, endFrame:Int, obj:Dynamic, properties:Dynamic, style:EaseFunction, onEvery:Int = 1) {
		super(frame);
		this.endFrame = endFrame;
		this.obj = obj;
		this.propertyInfo = [
			for (p in Reflect.fields(properties)) {
				var v = Reflect.field(properties, p);
				{
					name: p,
					value: v
				}
			}
		];
		this.style = style;
		this.updateInterval = onEvery;

		length = endFrame - frame;
	}

	override function execute(curFrame:Int, frameTime:Float):Void {
		var passed:Float = curFrame - frame;
		progress = Math.min(1, passed / (endFrame - frame));

		if (curFrame % updateInterval == 0) {
			for (data in propertyInfo) {
				if (data.range == null) {
					var sv:Float = Reflect.getProperty(obj, data.name);
					data.startValue = sv;
					data.range = data.value - sv;
				}
				Reflect.setProperty(obj, data.name, (data.range * style(progress)) + data.startValue);
			}
		}
		if (progress >= 1)
			finished = true;
	}
}

class EaseCallbackAction extends TimelineAction {
	public var endFrame:Int = 0;
	public var callback:(Float, Float) -> Void;
	public var style:EaseFunction = FlxEase.quadOut;

	public var progress:Float = 0;

	var length:Int = 0;
	var value:Float = 0;

	public function new(frame:Int, endFrame:Int, callback:(Float, Float) -> Void, style:EaseFunction) {
		super(frame);
		this.endFrame = endFrame;
		this.style = style;
		this.callback = callback;

		length = endFrame - frame;
	}

	override function execute(curFrame:Int, frameTime:Float):Void {
		var passed:Float = curFrame - frame;
		progress = Math.min(1, passed / (endFrame - frame));

		value = style(passed / length);
		callback(value, curFrame);

		if (progress >= 1)
			finished = true;
	}
}