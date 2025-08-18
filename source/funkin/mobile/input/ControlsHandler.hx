package funkin.mobile.input;

import openfl.events.KeyboardEvent;
import openfl.events.TouchEvent;

/**
 * Handles setting up and managing input controls for the game.
 */
class ControlsHandler {
	/**
	 * Returns wether the last input was sent through touch.
	 */
	public static var lastInputTouch(default, null):Bool = #if mobile true #else false #end;

    /**
     * Returns wether there's a keyboard connected and active.
     */
    public static var hasKeyboard(default, null):Bool = false;

	/**
	 * Returns wether there's a gamepad or keyboard devices connected and active.
	 */
	public static var hasExternalInputDevice(get, never):Bool;

	/**
	 * Returns wether an external input device is currently used as the main input.
	 */
	public static var usingExternalInputDevice(get, never):Bool;

	/**
	 * Initialize input trackers used to get the current status of the `lastInputTouch` field.
	 */
	public static function initInputTrackers():Void {
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, (_) -> {
            hasKeyboard = true;
            lastInputTouch = false;
        });
		FlxG.stage.addEventListener(TouchEvent.TOUCH_BEGIN, (_) -> lastInputTouch = true);
	}

	@:noCompletion
	private static function get_hasExternalInputDevice():Bool {
		return hasKeyboard || FlxG.gamepads.numActiveGamepads > 0;
	}

	@:noCompletion
	private static function get_usingExternalInputDevice():Bool {
		return hasExternalInputDevice && !lastInputTouch;
	}
}
