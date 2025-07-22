package funkin.graphics;

import haxe.io.Path;

import flixel.FlxObject;
import flixel.math.FlxPoint;

import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * Enum to store the mode (or direction) that a tracking sprite tracks.
 */
enum abstract TrackingMode(Int) to Int from Int {
	final RIGHT = 0;
	final LEFT = 1;
	final UP = 2;
	final DOWN = 3;
	final DIRECT = 4;
}

/**
 * A sprite that tracks another sprite with customizable offsets.
 * @author Leather128
 */
class TrackingSprite extends FilteredSprite {
	/**
	 * The offset in X and Y to the tracked object.
	 */
	public var trackingOffset:FlxPoint = FlxPoint.get(10, -30);

	/**
	 * The object / sprite we are tracking.
	 */
	public var tracked:FlxObject;

	/**
	 * Tracking mode (or direction) of this sprite.
	 */
	public var trackingMode:TrackingMode = RIGHT;

	/**
	 * Whether or not to copy the alpha from
	 * the sprite being tracked.
	 */
	public var copyAlpha:Bool = true;

	/**
	 * Multiplier for the alpha value.
	 */
	public var alphaMult:Float = 1;

	/**
	 * Whether or not to copy the visibility from
	 * the sprite being tracked.
	 */
	public var copyVisibility:Bool = true;

	/**
	 * Whether or not to copy the scroll factor from
	 * the sprite being tracked.
	 */
	public var copyScrollFactor:Bool = true;

	/**
	 * Whether or not to copy the angle from
	 * the sprite being tracked.
	 */
	public var copyAngle:Bool = true;

	/**
	 * An offset to add to this sprite's angle.
	 */
	public var angleOffset:Float = 0;

	public function new(?file:String = null, ?anim:String = null, ?parentFolder:String = null, ?loop:Bool = false) {
		super();
		if(anim != null) {
			frames = Paths.getSparrowAtlas(Path.join([parentFolder, file]));
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		} else if(file != null)
			loadGraphic(Paths.image(Path.join([parentFolder, file])));
	}

	override function update(elapsed:Float):Void {
		// tracking modes
		if(tracked != null) {
			switch(trackingMode) {
				case RIGHT:
					setPosition(tracked.x + tracked.width + trackingOffset.x, tracked.y + trackingOffset.y);

				case LEFT:
					setPosition(tracked.x + trackingOffset.x, tracked.y + trackingOffset.y);

				case UP:
					setPosition(tracked.x + (tracked.width * 0.5) + trackingOffset.x, tracked.y - height + trackingOffset.y);

				case DOWN:
					setPosition(tracked.x + (tracked.width * 0.5) + trackingOffset.x, tracked.y + tracked.height + trackingOffset.y);

				case DIRECT:
					setPosition(tracked.x + trackingOffset.x, tracked.y + trackingOffset.y);
			}
            final isTrackingSprite:Bool = (tracked is FlxSprite);
            if(isTrackingSprite) {
                final sprite:FlxSprite = cast tracked;
                if(copyAlpha)
                    alpha = sprite.alpha * alphaMult;

                if(copyVisibility)
                    visible = sprite.visible;

				if(copyScrollFactor)
					scrollFactor.copyFrom(sprite.scrollFactor);
				
				if(copyAngle)
					angle = sprite.angle + angleOffset;
            }
		}
		super.update(elapsed);
	}

	/**
	 * Load an image from an embedded graphic file.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you load an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the `pixels` field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * @param   Graphic    The image you want to use.
	 * @param   Animated   Whether the `Graphic` parameter is a single sprite or a row / grid of sprites.
	 * @param   Width      Specify the width of your sprite
	 *                     (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   Height     Specify the height of your sprite
	 *                     (helps figure out what to do with non-square sprites or sprite sheets).
	 * @param   Unique     Whether the graphic should be a unique instance in the graphics cache.
	 *                     Set this to `true` ifyou want to modify the `pixels` field without changing
	 *                     the `pixels` of other sprites with the same `BitmapData`.
	 * @param   Key        Set this parameter ifyou're loading `BitmapData`.
	 * @return  This `TrackingSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):TrackingSprite {
		super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
		return this;
	}

	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you make an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the pixels field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * @param   Width    The width of the sprite you want to generate.
	 * @param   Height   The height of the sprite you want to generate.
	 * @param   Color    Specifies the color of the generated block (ARGB format).
	 * @param   Unique   Whether the graphic should be a unique instance in the graphics cache. Default is `false`.
	 *                   Set this to `true` ifyou want to modify the `pixels` field without changing the
	 *                   `pixels` of other sprites with the same `BitmapData`.
	 * @param   Key      An optional `String` key to identify this graphic in the cache.
	 *                   If`null`, the key is determined by `Width`, `Height` and `Color`.
	 *                   If`Unique` is `true` and a graphic with this `Key` already exists,
	 *                   it is used as a prefix to find a new unique name like `"Key3"`.
	 * @return  This `TrackingSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):TrackingSprite {
		super.makeGraphic(Width, Height, Color, Unique, Key);
		return this;
	}

	/**
	 * This function creates a flat colored rectangular image dynamically.
	 *
	 * HaxeFlixel's graphic caching system keeps track of loaded image data.
	 * When you make an identical copy of a previously used image, by default
	 * HaxeFlixel copies the previous reference onto the pixels field instead
	 * of creating another copy of the image data, to save memory.
	 *
	 * @param   Width    The width of the sprite you want to generate.
	 * @param   Height   The height of the sprite you want to generate.
	 * @param   Color    Specifies the color of the generated block (ARGB format).
	 * @param   Unique   Whether the graphic should be a unique instance in the graphics cache. Default is `false`.
	 *                   Set this to `true` ifyou want to modify the `pixels` field without changing the
	 *                   `pixels` of other sprites with the same `BitmapData`.
	 * @param   Key      An optional `String` key to identify this graphic in the cache.
	 *                   If`null`, the key is determined by `Width`, `Height` and `Color`.
	 *                   If`Unique` is `true` and a graphic with this `Key` already exists,
	 *                   it is used as a prefix to find a new unique name like `"Key3"`.
	 * @return  This `TrackingSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function makeSolid(Width:Float, Height:Float, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):TrackingSprite {
		super.makeSolid(Width, Height, Color, Unique, Key);
		return this;
	}

    // --------------- //
    // [ Private API ] //
    // --------------- //

	override function destroy() {
		trackingOffset = FlxDestroyUtil.put(trackingOffset);
		super.destroy();
	}
}