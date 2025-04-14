package funkin.scripting.helpers;

import flixel.FlxCamera.FlxCameraFollowStyle;

class FlxCameraFollowStyleHelper {
	/**
	 * Camera has no deadzone, just tracks the focus object directly.
	 */
	public static var LOCKON = FlxCameraFollowStyle.LOCKON;

	/**
	 * Camera's deadzone is narrow but tall.
	 */
	public static var PLATFORMER = FlxCameraFollowStyle.PLATFORMER;

	/**
	 * Camera's deadzone is a medium-size square around the focus object.
	 */
	public static var TOPDOWN = FlxCameraFollowStyle.TOPDOWN;

	/**
	 * Camera's deadzone is a small square around the focus object.
	 */
	public static var TOPDOWN_TIGHT = FlxCameraFollowStyle.TOPDOWN_TIGHT;

	/**
	 * Camera will move screenwise.
	 */
	public static var SCREEN_BY_SCREEN = FlxCameraFollowStyle.SCREEN_BY_SCREEN;

	/**
	 * Camera has no deadzone, just tracks the focus object directly and centers it.
	 */
	public static var NO_DEAD_ZONE = FlxCameraFollowStyle.NO_DEAD_ZONE;
}