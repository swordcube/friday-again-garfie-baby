package funkin.graphics;

import animate.FlxAnimate;

import flixel.graphics.frames.FlxAtlasFrames;
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
		if (alpha <= 0.0 || Math.abs(scale.x) < 0.0000001 || Math.abs(scale.y) < 0.0000001)
			return;

		_matrix.setTo(this.checkFlipX() ? -1 : 1, 0, 0, this.checkFlipY() ? -1 : 1, 0, 0);

		if (applyStageMatrix)
			_matrix.concat(library.matrix);

        _matrix.translate(-origin.x, -origin.y);

		var _animOffset:FlxPoint = animation.curAnim?.offset ?? FlxPoint.weak();
		if (frameOffsetAngle != null && frameOffsetAngle != angle)
		{
			var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
			_matrix.rotate(-angleOff);
			_matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));
			_matrix.rotate(angleOff);
		}
		else
			_matrix.translate(-(frameOffset.x + _animOffset.x), -(frameOffset.y + _animOffset.y));

		_matrix.scale(scale.x, scale.y);
		_animOffset.putWeak();
		
		if (angle != 0)
		{
			updateTrig();
			_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			_matrix.concat(FlxAnimate._skewMatrix);
		}

		getScreenPosition(_point, camera);
		_point.add(-offset.x, -offset.y);
		_point.add(origin.x, origin.y);

		if (!useLegacyBounds)
		{
			@:privateAccess
			var bounds = timeline._bounds;
			_point.add(-bounds.x, -bounds.y);
		}

		_matrix.translate(_point.x, _point.y);

		if (renderStage)
			drawStage(camera);

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, _matrix, colorTransform, blend, antialiasing, shader);
	}
}