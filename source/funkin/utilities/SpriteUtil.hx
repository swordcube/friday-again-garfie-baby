package funkin.utilities;

import flixel.math.FlxPoint;
import flixel.animation.FlxAnimation;

class SpriteUtil {
	@:noUsing
    public static function switchAnimFrames(anim1:FlxAnimation, anim2:FlxAnimation):Void {
		if(anim1 == null || anim2 == null)
            return;
        
        final old:Array<Int> = anim1.frames;
		anim1.frames = anim2.frames;
		anim2.frames = old;
	}

    @:noUsing
    public static function switchAnimOffset(anim1:FlxAnimation, anim2:FlxAnimation):Void {
		final old:FlxPoint = anim1.offset;
		anim1.offset = anim2.offset;
		anim2.offset = old;
	}
}