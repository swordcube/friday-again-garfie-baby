package funkin.graphics;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawQuadsItem;

using flixel.util.FlxColorTransformUtil;

// TODO: more customization? (animated tails, rotated frames)
// TODO: account for more edge cases when checking offscreen tiles?
// TODO: bending? triangle rendering?

// ---------------------------------------------------------- //
// All rights of this class go towards Sword352, and as such, //
// all permissions goes to them aswell.                       //
// ---------------------------------------------------------- //

/**
 * An object able to vertically repeat an `FlxFrame` by an arbitary amount.
 * This class has been built for hold note trails in mind.
 * 
 * @author Sword352
 * @see https://github.com/Sword352/FnF-Eternal/blob/dev/src/funkin/objects/display/TiledSprite.hx
 */
class TiledSprite extends SkinnableSprite {
	/**
	 * How many times the frame should repeat.
	 */
	public var tiles(default, set):Float;

	/**
	 * The tail gets it's own dedicated matrix transformation
	 * to ensure proper applications of frame-related properties
	 * such as offsets and rotations.
	 */
	var _tailMatrix:FlxMatrix = new FlxMatrix();
	var _tailFrame:FlxFrame;

	/**
	 * This variable holds a copy of the first or last tile's frame (depends on flipY).
	 * It is clipped to account for the decimal part of `tiles`.
	 * For example, this object would render 1 tile and a half when `tiles` equals `1.5`.
	 */
	var _clippedTileFrame:FlxFrame;

	/**
	 * When clipping a flipped frame, a gap would appear between the clipped and last rendered tile.
	 * This value is used to compensate for the gap by offsetting the position of the tile.
	 */
	var _clippingOffset:Float = 0;

	var _clippingDirty:Bool = false;
	var _quadAmount:Int = 0;
	
	/**
	 * Sets the tail frame for this sprite.
	 * @param animation Animation containing the desired tail frames. If `null`, no tail is rendered.
	 */
	public function setTail(animation:String):Void {
	    if (animation == null) {
	        _tailFrame = null;
	        return;
	    }
	    
	    var anim:FlxAnimation = this.animation.getByName(animation);
	    
	    if (anim == null) {
	        FlxG.log.warn('TiledSprite: Could not find tail animation "${animation}"!');
	        _tailFrame = null;
	        return;
	    }

	    // copy the frame and modify coordinates to workaround texture bleeding gaps
		var frame:FlxFrame = frames.frames[anim.frames[0]];
	    _tailFrame = frame.copyTo(_tailFrame);

		_tailFrame.sourceSize.y -= 2;
	    _tailFrame.frame.height -= 2;
	    _tailFrame.frame.y += 2;
	}

	@:inheritDoc(flixel.FlxSprite.getScreenBounds)
	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (newRect == null)
			newRect = FlxRect.get();
		
		if (camera == null)
			camera = getDefaultCamera();
		
		var _animOffset:FlxPoint = animation.curAnim?.offset ?? FlxPoint.weak();
		newRect.setPosition(x, y);
		
		if (pixelPerfectPosition)
			newRect.floor();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		_scaledFrameOffset.set((frameOffset.x + _animOffset.x) * Math.abs(scale.x), (frameOffset.y + _animOffset.y) * Math.abs(scale.y));

		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

		if (isPixelPerfectRender(camera))
			newRect.floor();

		newRect.setSize((frameWidth * Math.abs(scale.x)) - frameOffset.x, height - frameOffset.y);
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect, _scaledFrameOffset);
	}

	override function draw():Void {
		if (_clippingDirty) {
			regenerateClippedFrame();
			_clippingDirty = false;
		}

		super.draw();
	}

	override function drawComplex(camera:FlxCamera):Void {
	    getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
        
		prepareMatrix(_frame, _matrix);
		prepareMatrix(_tailFrame, _tailMatrix);

		var drawItem:FlxDrawQuadsItem = camera.startQuadBatch(_frame.parent, colorTransform?.hasRGBMultipliers(), colorTransform?.hasRGBAOffsets(), blend, antialiasing, shader);
		var screenOffset:Float = (flipY ? tileHeight() : 0);

		for (i in getFirstTileOnScreen(camera)..._quadAmount) {
			drawTile(i, drawItem);

			// if it's offscreen, stop rendering
			if (_matrix.ty >= camera.viewMarginBottom + screenOffset) {
				break;
			}
		}
    }

	function drawTile(tile:Int, item:FlxDrawQuadsItem):Void {
		var frame:FlxFrame = _frame;
		var isTail:Bool = isTail(tile);
		
		if (isTileClipped(tile)) {
			frame = _clippedTileFrame;
			if (_clippingOffset > 0) {
				matrixTranslate(-_clippingOffset);
			}
		} else if (isTail) {
			frame = _tailFrame;
		}

		item.addQuad(frame, isTail ? _tailMatrix : _matrix, colorTransform);
		matrixTranslate(frame.frame.height * Math.abs(scale.y));
	}

	function regenerateClippedFrame():Void {
		var parentFrame:FlxFrame = (_tailFrame != null && _quadAmount == 1) ? _tailFrame : _frame;
		var reduction:Float = parentFrame.frame.height * (_quadAmount - tiles);

		_clippedTileFrame = parentFrame.copyTo(_clippedTileFrame);
		_clippedTileFrame.frame.height -= reduction;
		_clippedTileFrame.frame.y += reduction;

		_clippingOffset = (flipY ? reduction * Math.abs(scale.y) : 0);
	}

	function prepareMatrix(frame:FlxFrame, matrix:FlxMatrix):Void {
	    if (frame == null) return;

	    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		matrix.translate(-origin.x, -origin.y);

		var _animOffset:FlxPoint = animation.curAnim?.offset ?? FlxPoint.weak();
		if (frameOffsetAngle != null && frameOffsetAngle != angle) {
			var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
			matrix.rotate(-angleOff);
			matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));
			matrix.rotate(angleOff);
		}
		else
			matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));
        
		matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0 && angle != 0)
			matrix.rotateWithTrig(_cosAngle, _sinAngle);

		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera)) {
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
		_animOffset.putWeak();
	}

	function matrixTranslate(y:Float):Void {
	    var translateX:Float = -y * _sinAngle;
	    var translateY:Float = y * _cosAngle;
	    
	    if (_tailFrame != null)
	        _tailMatrix.translate(translateX, translateY);
	        
	    _matrix.translate(translateX, translateY);
	}

	function getFirstTileOnScreen(camera:FlxCamera):Int {
		var offscreenHeight:Float = camera.viewMarginTop - _point.y;
		if (offscreenHeight <= 0) return 0;

		var nextTileHeight:Float = getHeightForTile(0);
		var output:Int = 0;

		while (offscreenHeight >= nextTileHeight) {
			matrixTranslate(nextTileHeight);
			offscreenHeight -= nextTileHeight;
			nextTileHeight = getHeightForTile(++output);
		}

		return output;
	}

	inline function isTileClipped(tile:Int):Bool {
		return (!flipY && tile == 0) || (flipY && tile == _quadAmount - 1);
	}
	
	inline function isTail(tile:Int):Bool {
		return _tailFrame != null && ((flipY && tile == 0) || (!flipY && tile == _quadAmount - 1));
	}

	inline function getHeightForTile(tile:Int):Float {
		return isTileClipped(tile) ? (_clippedTileFrame.frame.height * Math.abs(scale.y)) : (isTail(tile) ? tailHeight() : tileHeight());
	}

	inline function tileHeight():Float {
		return _frame.frame.height * Math.abs(scale.y);
	}
	
	inline function tailHeight():Float {
	    return _tailFrame.frame.height * Math.abs(scale.y);
	}
	
	override function set_frame(v:FlxFrame):FlxFrame {
		var oldFrame:FlxFrame = frame;
	    super.set_frame(v);

		if (v == null) return v;
	    
	    if (_frame != null) {
	        // texture bleeding gap workaround
			_frame.sourceSize.y -= 2;
	        _frame.frame.height -= 2;
	        _frame.frame.y += 1;
	    }

		if (v != oldFrame) {
			_clippingDirty = true;
		}

	    return v;
	}
	
	override function set_angle(v:Float):Float {
		super.set_angle(v);
		updateTrig();
		return v;
	}

	override function set_height(v:Float):Float {
		if (height != v) {
			tiles = v / tileHeight();
		}
		return super.set_height(v);
	}

	override function set_flipY(v:Bool):Bool {
		if (flipY != v) {
			_clippingDirty = true;
		}
		return super.set_flipY(v);
	}

	function set_tiles(v:Float):Float {
		if (tiles != v) {
			_quadAmount = Math.ceil(v);
			_clippingDirty = true;
		}
		return tiles = v;
	}

	override function destroy():Void {
		_clippedTileFrame = FlxDestroyUtil.destroy(_clippedTileFrame);
		_tailFrame = FlxDestroyUtil.destroy(_tailFrame);
		_tailMatrix = null;
		super.destroy();
	}
}