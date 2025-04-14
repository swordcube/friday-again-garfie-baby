package funkin.scripting.helpers;

import flixel.tweens.FlxTween.FlxTweenType;

class FlxTweenTypeHelper {
	/**
	 * Persistent Tween type, will stop when it finishes.
	 */
	public static var PERSIST = FlxTweenType.PERSIST;

	/**
	 * Looping Tween type, will restart immediately when it finishes.
	 */
	public static var LOOPING = FlxTweenType.LOOPING;

	/**
	 * "To and from" Tween type, will play tween hither and thither
	 */
	public static var PINGPONG = FlxTweenType.PINGPONG;

	/**
	 * Oneshot Tween type, will stop and remove itself from its core container when it finishes.
	 */
	public static var ONESHOT = FlxTweenType.ONESHOT;

	/**
	 * Backward Tween type, will play tween in reverse direction
	 */
	public static var BACKWARD = FlxTweenType.BACKWARD;
}