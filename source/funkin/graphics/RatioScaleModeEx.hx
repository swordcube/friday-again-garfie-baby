package funkin.graphics;

import flixel.system.scaleModes.RatioScaleMode;

/**
 * @see https://github.com/FNF-CNE-Devs/CodenameEngine/blob/main/source/funkin/backend/system/FunkinRatioScaleMode.hx
 */
class RatioScaleModeEx extends RatioScaleMode {
	/**
	 * The width of the game area, in pixels.
	 */
	@:isVar public var width(get, set):Null<Int> = null;

	/**
	 * The height of the game area, in pixels.
	 */
	@:isVar public var height(get, set):Null<Int> = null;

	override function updateGameSize(Width:Int, Height:Int):Void {
		var ratio:Float = width / height;
		var realRatio:Float = Width / Height;

		var scaleY:Bool = realRatio < ratio;
		if (fillScreen)
			scaleY = !scaleY;

		if (scaleY) {
			gameSize.x = Width;
			gameSize.y = Math.floor(gameSize.x / ratio);
		} else {
			gameSize.y = Height;
			gameSize.x = Math.floor(gameSize.y * ratio);
		}
		@:privateAccess {
			for (c in FlxG.cameras.list) {
				if (c.width == FlxG.width && c.height == FlxG.height) {
					c.width = width;
					c.height = height;
				}
			}
			FlxG.width = width;
			FlxG.height = height;
		}
	}

	public function resetSize():Void {
		width = null;
		height = null;
	}

    // --------------- //
    // [ Private API ] //
    // --------------- //

	private inline function get_width():Null<Int> {
		return this.width == null ? FlxG.initialWidth : this.width;
    }

	private inline function get_height():Null<Int> {
		return this.height == null ? FlxG.initialHeight : this.height;
    }

	private inline function set_width(v:Null<Int>):Null<Int> {
		this.width = v;
		@:privateAccess
		FlxG.game.onResize(null);
		return v;
	}

	private inline function set_height(v:Null<Int>):Null<Int> {
		this.height = v;
		@:privateAccess
		FlxG.game.onResize(null);
		return v;
	}
}
