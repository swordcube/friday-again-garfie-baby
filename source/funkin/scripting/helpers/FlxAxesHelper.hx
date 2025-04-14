package funkin.scripting.helpers;

import flixel.util.FlxAxes;

class FlxAxesHelper {
	public static var X:FlxAxes = FlxAxes.X;
	public static var Y:FlxAxes = FlxAxes.Y;
	public static var XY:FlxAxes = FlxAxes.XY;
	public static var NONE:FlxAxes = FlxAxes.NONE;

	public static function toString(axes:FlxAxes):String {
		return switch (axes) {
			case FlxAxes.X: "x";
			case FlxAxes.Y: "y";
			case FlxAxes.XY: "xy";
			case FlxAxes.NONE: "none";
		}
	}

	public static function fromBools(x:Bool, y:Bool):FlxAxes {
		return cast(x ? (cast X : Int) : 0) | (y ? (cast Y : Int) : 0);
	}

	public static function fromString(axes:String):FlxAxes {
		return switch (axes.toLowerCase()) {
			case "x": X;
			case "y": Y;
			case "xy" | "yx" | "both": XY;
			case "none" | "" | null: NONE;
			default: NONE;
		}
	}
}