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

	/**
     * Resets an FlxSprite.
     * 
     * @param  spr  Sprite to reset
     * @param  x    New X position
     * @param  y    New Y position
     */
    public static function resetSprite(spr:FlxSprite, x:Float, y:Float):Void {
        spr.reset(x, y);
        spr.alpha = 1;
        spr.visible = true;
        spr.active = true;
        spr.acceleration.set();
        spr.velocity.set();
        spr.drag.set();
        spr.antialiasing = FlxSprite.defaultAntialiasing;
        spr.frameOffset.set();
        FlxTween.cancelTweensOf(spr);
    }
}