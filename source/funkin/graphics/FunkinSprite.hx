package funkin.graphics;

import animate.FlxAnimate;
import flixel.system.FlxAssets.FlxGraphicAsset;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;

import flixel.util.FlxAxes;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;

/**
 * An extension of `FlxSprite` which can both load normal
 * graphics and atlases, along with Adobe Animate texture atlases.
 * 
 * Also contains some small utility functions for loading
 * these atlases, to make your life a lil bit easier.
 */
@:access(animate.FlxAnimate)
class FunkinSprite extends FlxAnimate {
	public var extra:Map<String, Dynamic> = [];

    public function loadFrames(frames:FlxFramesCollection):FunkinSprite {
        this.frames = frames;
        return this;
    }

    public function loadSparrowFrames(img:String):FunkinSprite {
        return loadFrames(Paths.getSparrowAtlas(img));
    }

    public function loadAnimateFrames(img:String):FunkinSprite {
        return loadFrames(Paths.getAnimateAtlas(img));
    }

    public function loadFromSheet(img:String, anim:String, fps:Float):FunkinSprite {
        frames = Paths.getSparrowAtlas(img);
        animation.addByPrefix(anim, anim, fps);
        animation.play(anim);

        if(animation.curAnim == null || animation.curAnim.numFrames == 1)
            active = false;

        return this;
    }

    public function setScale(val:Float, axes:FlxAxes, ?updateHitbox:Bool = true):FunkinSprite {
        if(axes.x)
            scale.x = val;

        if(axes.y)
            scale.y = val;

        if(updateHitbox)
            this.updateHitbox();

        return this;
    }

    override function drawAnimate(camera:FlxCamera) {
		if(alpha <= 0.0 || Math.abs(scale.x) < 0.0000001 || Math.abs(scale.y) < 0.0000001)
			return;

		var mat = _matrix;
		mat.identity();

		@:privateAccess
		var bounds = timeline._bounds;
		mat.translate(-bounds.x, -bounds.y);

		var doFlipX = this.checkFlipX();
		var doFlipY = this.checkFlipY();

		if(doFlipX) {
			mat.scale(-1, 1);
			mat.translate(frame.sourceSize.x, 0);
		}
		if(doFlipY) {
			mat.scale(1, -1);
			mat.translate(0, frame.sourceSize.y);
		}
		if(applyStageMatrix)
			mat.concat(library.matrix);

		mat.translate(-origin.x, -origin.y);
		mat.scale(scale.x, scale.y);

		var _animOffset:FlxPoint = animation.curAnim?.offset ?? FlxPoint.weak();
		if(frameOffsetAngle != null && frameOffsetAngle != angle) {
			var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
			mat.rotate(-angleOff);
			mat.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));
			mat.rotate(angleOff);
		}
		else
			mat.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));

		_animOffset.putWeak();
		
		if(angle != 0) {
			updateTrig();
			mat.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if(skew.x != 0 || skew.y != 0) {
			updateSkew();
			mat.concat(FlxAnimate._skewMatrix);
		}
		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		mat.translate(_point.x, _point.y);

		if(renderStage)
			drawStage(camera);

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, mat, colorTransform, blend, antialiasing, shader);
	}

	// I dont think theres a way to override the matrix without needing to do this lol
	#if (flixel >= "6.1.0")
	override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
	#else
	override function drawComplex(camera:FlxCamera):Void
	#end
	{
		#if (flixel < "6.1.0") final frame = this._frame; #end
		final matrix = this._matrix; // TODO: Just use local?

		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		matrix.translate(-origin.x, -origin.y);

		var _animOffset:FlxPoint = animation.curAnim?.offset ?? FlxPoint.weak();
		if(frameOffsetAngle != null && frameOffsetAngle != angle) {
			var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
			matrix.rotate(-angleOff);
			matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));
			matrix.rotate(angleOff);
		} else
			matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));

		matrix.scale(scale.x, scale.y);
		if(bakedRotationAngle <= 0) {
			updateTrig();
			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if(skew.x != 0 || skew.y != 0) {
			updateSkew();
			_matrix.concat(FlxAnimate._skewMatrix);
		}
		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		matrix.translate(_point.x, _point.y);

		if(isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
		camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
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
	 * @return  This `FunkinSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FunkinSprite {
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
	 * @return  This `FunkinSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FunkinSprite {
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
	 * @return  This `FunkinSprite` instance (nice for chaining stuff together, ifyou're into that).
	 */
	override function makeSolid(Width:Float, Height:Float, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FunkinSprite {
		super.makeSolid(Width, Height, Color, Unique, Key);
		return this;
	}
}