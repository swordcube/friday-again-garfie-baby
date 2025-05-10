package funkin.utilities;

import flixel.math.FlxMath;

/**
 * A class containing several utilities for strings.
 */
class StringUtil {
    @:unreflective
    @:noCompletion
    private static final _byteUnits:Array<String> = ["b", "kb", "mb", "gb", "tb", "pb"];

	/**
	 * Takes an amount of bytes and finds the fitting unit. Makes sure that the
	 * value is below 1024. Example: formatBytes(123456789); -> 117.74MB
	 */
	public static function formatBytes(bytes:Float, precision:Int = 2):String {
        var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < _byteUnits.length - 1) {
			bytes /= 1024;
			curUnit++;
		}
		return FlxMath.roundDecimal(bytes, precision) + _byteUnits[curUnit];
	}

	public static function getDefaultString(str:String, defaultStr:String):String {
		return (str != null && str.length != 0) ? str : defaultStr;
	}

	public static function capitalize(text:String):String {
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}
}
