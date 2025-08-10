package funkin.utilities;

import flixel.util.FlxAxes;
import flixel.input.FlxSwipe;

/**
 * Utility class for handling swipe gestures in HaxeFlixel and dispatching signals for different swipe directions.
 *
 * Example usage:
 *
 * ```haxe
 * if (SwipeUtil.justSwipedLeft) trace("Swiped left!");
 *
 * if (SwipeUtil.swipeRight) trace("User is swiping/dragging right!");
 *
 * if (SwipeUtil.justFlickedUp) trace("Flicked up!");
 *
 * if (SwipeUtil.flickUp) trace("User has flicked up!");
 *
 * if (SwipeUtil.justSwipedAny) trace("Swiped in any direction!");
 * ```
 */
class SwipeUtil {
	/**
	 * Tracks if an upward swipe has been detected.
	 */
	public static var swipeUp(default, null):Bool;

	/**
	 * Tracks if a rightward swipe has been detected.
	 */
	public static var swipeRight(default, null):Bool;

	/**
	 * Tracks if a leftward swipe has been detected.
	 */
	public static var swipeLeft(default, null):Bool;

	/**
	 * Tracks if a downward swipe has been detected.
	 */
	public static var swipeDown(default, null):Bool;

	/**
	 * Tracks if any swipe direction is detected (down, left, up, or right).
	 */
	public static var swipeAny(default, null):Bool;

	/**
	 * Indicates if there is an up swipe gesture detected.
	 */
	public static var justSwipedUp(default, null):Bool;

	/**
	 * Indicates if there is a right swipe gesture detected.
	 */
	public static var justSwipedRight(default, null):Bool;

	/**
	 * Indicates if there is a left swipe gesture detected.
	 */
	public static var justSwipedLeft(default, null):Bool;

	/**
	 * Indicates if there is a down swipe gesture detected.
	 */
	public static var justSwipedDown(default, null):Bool;

	/**
	 * Indicates if there is any swipe gesture detected.
	 */
	public static var justSwipedAny(default, null):Bool;

	/**
	 * Checks if an upward flick direction is detected.
	 */
	public static var flickUp(default, null):Bool;

	/**
	 * Checks if a rightward flick direction is detected.
	 */
	public static var flickRight(default, null):Bool;

	/**
	 * Checks if a leftward flick direction is detected.
	 */
	public static var flickLeft(default, null):Bool;

	/**
	 * Checks if a downward flick direction is detected.
	 */
	public static var flickDown(default, null):Bool;

	/**
	 *  Boolean variable that returns true if any flick direction is detected (down, left, up, or right).
	 */
	public static var flickAny(default, null):Bool;

	public static function init():Void {
		FlxG.signals.preUpdate.add(update);
	}

	/**
	 * Updates the swipe threshold based on the provided group.
	 *
	 * @param items The array whose items' positions are used to calculate the swipe threshold.
	 * @param axes The axis to calculate the swipe threshold for.
	 * @param multiplier Optional value that multiplies the final swipe threshold with it.
	 */
	public static function calculateSwipeThreshold(items:Array<Dynamic>, axes:FlxAxes, ?multiplier:Float = 1):Void {
		#if mobile
		final itemCount:Int = items.length - 1;

		if (itemCount <= 0) {
			FlxG.touches.swipeThreshold.set(100, 100);
			return;
		}

		var totalDistanceX:Float = 0;
		var totalDistanceY:Float = 0;

		for (i in 0...itemCount) {
			if (axes.x)
				totalDistanceX += Math.abs(items[i + 1].x - items[i].x);
			if (axes.y)
				totalDistanceY += Math.abs(items[i + 1].y - items[i].y);
		}

		totalDistanceX = Math.abs((totalDistanceX / itemCount) * 0.9);
		totalDistanceY = Math.abs((totalDistanceY / itemCount) * 0.9);

		FlxG.touches.swipeThreshold.x = (axes.x) ? totalDistanceX * multiplier : 100;
		FlxG.touches.swipeThreshold.y = (axes.y) ? totalDistanceY * multiplier : 100;
		#end
		return;
	}

	@:noCompletion
	static function update():Void {
		#if mobile
		final swipe:FlxSwipe = (FlxG.swipes.length > 0) ? FlxG.swipes[0] : null;
		
		swipeUp = TouchUtil.touch?.justMovedUp ?? false;
		swipeDown = TouchUtil.touch?.justMovedDown ?? false;
		swipeLeft = TouchUtil.touch?.justMovedLeft ?? false;
		swipeRight = TouchUtil.touch?.justMovedRight ?? false;
		
		justSwipedUp = swipe?.degrees > 45 && swipe?.degrees < 135 && swipe?.distance > 20;
		justSwipedDown = swipe?.degrees > -135 && swipe?.degrees < -45 && swipe?.distance > 20;
		justSwipedLeft = (swipe?.degrees > 135 || swipe?.degrees < -135) && swipe?.distance > 20;
		justSwipedRight = swipe?.degrees > -45 && swipe?.degrees < 45 && swipe?.distance > 20;

		flickUp = FlxG.touches.flickManager.flickUp;
		flickDown = FlxG.touches.flickManager.flickDown;
		flickLeft = FlxG.touches.flickManager.flickLeft;
		flickRight = FlxG.touches.flickManager.flickRight;
		#else
		swipeUp = FlxG.mouse.justMovedUp && FlxG.mouse.pressed;
		swipeDown = FlxG.mouse.justMovedDown && FlxG.mouse.pressed;
		swipeLeft = FlxG.mouse.justMovedLeft && FlxG.mouse.pressed;
		swipeRight = FlxG.mouse.justMovedRight && FlxG.mouse.pressed;

		justSwipedUp = false;
		justSwipedDown = false;
		justSwipedLeft = false;
		justSwipedRight = false;

		flickUp = FlxG.mouse.flickManager.flickUp;
		flickDown = FlxG.mouse.flickManager.flickDown;
		flickLeft = FlxG.mouse.flickManager.flickLeft;
		flickRight = FlxG.mouse.flickManager.flickRight;
		#end
		swipeAny = swipeUp || swipeDown || swipeLeft || swipeRight;
		justSwipedAny = justSwipedUp || justSwipedDown || justSwipedLeft || justSwipedRight;
		flickAny = flickUp || flickDown || flickLeft || flickRight;
	}

	/**
	 * Calls the destroy function from both the global mouse and the touch manager.
	 */
	public static inline function resetSwipeVelocity():Void {
		FlxG.mouse.flickManager.destroy();
		FlxG.touches.flickManager.destroy();
	}
}
