package funkin.utilities;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepad.FlxGamepadModel;

import flixel.system.macros.FlxMacroUtil;

class InputFormatter {
    public static var keyCodeFromStringMap(default, null):Map<String, lime.ui.KeyCode> = FlxMacroUtil.buildMap("lime.ui.KeyCode");
    public static var keyCodeToStringMap(default, null):Map<lime.ui.KeyCode, String> = FlxMacroUtil.buildMap("lime.ui.KeyCode", true);

    /**
     * Converts a lime `KeyCode` to a human-readable
     * string representation.
     * 
     * @param  key  The key to convert.
     */
    public static function formatLimeKey(key:Null<lime.ui.KeyCode>):String {
        return switch (key) {
            case null, UNKNOWN: "---";
            case LEFT: "Left";
            case DOWN: "Down";
            case UP: "Up";
            case RIGHT: "Right";
            case RETURN, RETURN2: "Enter";
            case LEFT_CTRL: "LCtrl";
            case RIGHT_CTRL: "RCtrl";
            case LEFT_SHIFT: "LShift";
            case RIGHT_SHIFT: "RShift";
            case LEFT_ALT: "LAlt";
            case RIGHT_ALT: "RAlt";
            case ESCAPE: "ESC";
            case BACKSPACE, NUMPAD_BACKSPACE: "BckSpc";
            case SPACE, NUMPAD_SPACE: "Space";
            case NUMPAD_0: "[#0]";
            case NUMPAD_1: "[#1]";
            case NUMPAD_2: "[#2]";
            case NUMPAD_3: "[#3]";
            case NUMPAD_4: "[#4]";
            case NUMPAD_5: "[#5]";
            case NUMPAD_6: "[#6]";
            case NUMPAD_7: "[#7]";
            case NUMPAD_8: "[#8]";
            case NUMPAD_9: "[#9]";
            case NUMPAD_PLUS: "[#+]";
            case NUMPAD_MINUS: "[#-]";
            case NUMPAD_PERIOD: "[#.]";
            case NUMPAD_MULTIPLY: "[#*]";
            case NUM_LOCK: "NumLock";
            case GRAVE: "`";
            case LEFT_BRACKET: "[";
            case RIGHT_BRACKET: "]";
            case PRINT_SCREEN: "PrtScrn";
            case QUOTE: "'";
            case NUMBER_0: "0";
            case NUMBER_1: "1";
            case NUMBER_2: "2";
            case NUMBER_3: "3";
            case NUMBER_4: "4";
            case NUMBER_5: "5";
            case NUMBER_6: "6";
            case NUMBER_7: "7";
            case NUMBER_8: "8";
            case NUMBER_9: "9";
            case COMMA: ",";
            case PERIOD: ".";
            case SEMICOLON: ";";
            case BACKSLASH: "\\";
            case SLASH: "/";
            case PAGE_UP: "PgUp";
            case PAGE_DOWN: "PgDown";
            case TAB, NUMPAD_TAB: "Tab";
            case PLUS: "+";
            case MINUS: "-";
            default: keyCodeToStringMap.get(key).toUpperCase();
        }
    }

    /**
     * Converts an `FlxKey` to a human-readable
     * string representation.
     * 
     * @param  key  The key to convert.
     */
    public static function formatFlixelKey(key:Null<FlxKey>):String {
        return switch (key) {
            case null, NONE: "---";
            case LEFT: "Left";
            case DOWN: "Down";
            case UP: "Up";
            case RIGHT: "Right";
            case ENTER: "Enter";
            case CONTROL: "Ctrl";
            case SHIFT: "Shift";
            case ALT: "Alt";
            case WINDOWS: #if (mac || macos) "Cmd" #else "Win" #end;
            case ESCAPE: "ESC";
            case BACKSPACE: "BckSpc";
            case DELETE: "Delete";
            case SPACE: "Space";
            case NUMPADZERO: "[#0]";
            case NUMPADONE: "[#1]";
            case NUMPADTWO: "[#2]";
            case NUMPADTHREE: "[#3]";
            case NUMPADFOUR: "[#4]";
            case NUMPADFIVE: "[#5]";
            case NUMPADSIX: "[#6]";
            case NUMPADSEVEN: "[#7]";
            case NUMPADEIGHT: "[#8]";
            case NUMPADNINE: "[#9]";
            case NUMPADPLUS: "[#+]";
            case NUMPADMINUS: "[#-]";
            case NUMPADPERIOD: "[#.]";
            case NUMPADMULTIPLY: "[#*]";
            case NUMLOCK: "NumLock";
            case GRAVEACCENT: "`";
            case LBRACKET: "[";
            case RBRACKET: "]";
            case PRINTSCREEN: "PrtScrn";
            case QUOTE: "'";
            case ZERO: "0";
            case ONE: "1";
            case TWO: "2";
            case THREE: "3";
            case FOUR: "4";
            case FIVE: "5";
            case SIX: "6";
            case SEVEN: "7";
            case EIGHT: "8";
            case NINE: "9";
            case COMMA: ",";
            case PERIOD: ".";
            case SEMICOLON: ";";
            case BACKSLASH: "\\";
            case SLASH: "/";
            case NUMPADSLASH: "[#/]";
            case PAGEUP: "PgUp";
            case PAGEDOWN: "PgDown";
            case TAB: "Tab";
            case PLUS: "+";
            case MINUS: "-";
            default: FlxKey.toStringMap.get(key).toUpperCase();
        }
    }

    public static function formatFlixelGamepadInput(input:Null<FlxGamepadInputID>):String {
        final gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		final model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		switch(input) {
			// Analogs
			case LEFT_STICK_DIGITAL_LEFT:
				return "Left";
            
			case LEFT_STICK_DIGITAL_RIGHT:
				return "Right";
            
			case LEFT_STICK_DIGITAL_UP:
				return "Up";
            
			case LEFT_STICK_DIGITAL_DOWN:
				return "Down";
            
			case LEFT_STICK_CLICK:
				switch (model) {
					case PS4: return "L3";
					case XINPUT: return "LS";
					default: return "Analog Click";
				}

			case RIGHT_STICK_DIGITAL_LEFT:
				return "C. Left";
            
			case RIGHT_STICK_DIGITAL_RIGHT:
				return "C. Right";
            
			case RIGHT_STICK_DIGITAL_UP:
				return "C. Up";
            
			case RIGHT_STICK_DIGITAL_DOWN:
				return "C. Down";
            
			case RIGHT_STICK_CLICK:
				switch (model) {
					case PS4: return "R3";
					case XINPUT: return "RS";
					default: return "C. Click";
				}

			// Directional
			case DPAD_LEFT:
				return "D. Left";
			case DPAD_RIGHT:
				return "D. Right";
			case DPAD_UP:
				return "D. Up";
			case DPAD_DOWN:
				return "D. Down";

			// Top buttons
			case LEFT_SHOULDER:
				switch(model) {
					case PS4: return "L1";
					case XINPUT: return "LB";
					default: return "L. Bumper";
				}
            
			case RIGHT_SHOULDER:
				switch(model) {
					case PS4: return "R1";
					case XINPUT: return "RB";
					default: return "R. Bumper";
				}
            
			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: return "L2";
					case XINPUT: return "LT";
					default: return "L. Trigger";
				}
            
			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: return "R2";
					case XINPUT: return "RT";
					default: return "R. Trigger";
				}

			// Buttons
			case A:
				switch (model) {
					case PS4: return "X";
					case XINPUT: return "A";
					default: return "Action Down";
				}
			case B:
				switch (model) {
					case PS4: return "O";
					case XINPUT: return "B";
					default: return "Action Right";
				}
			case X:
				switch (model) {
					case PS4: return "["; // TODO: change this image in code later
					case XINPUT: return "X";
					default: return "Action Left";
				}
			case Y:
				switch (model) { 
					case PS4: return "]"; // TODO: change this image in code later
					case XINPUT: return "Y";
					default: return "Action Up";
				}

			case BACK:
				switch(model) {
					case PS4: return "Share";
					case XINPUT: return "Back";
					default: return "Select";
				}
			case START:
				switch(model) {
					case PS4: return "Options";
					default: return "Start";
				}

			case NONE:
				return '---';

			default:
				var label:String = Std.string(input);
				if(label.toLowerCase() == 'null') return '---';

				var arr:Array<String> = label.split('_');
				for (i in 0...arr.length) arr[i] = StringUtil.capitalize(arr[i]);
				return arr.join(' ');
        }
    }
}