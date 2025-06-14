package funkin.graphics;

import animate.FlxAnimate;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;

import flixel.util.FlxAxes;

/**
 * An extension of `FlxSprite` which can both load normal
 * graphics and atlases, along with Adobe Animate texture atlases.
 * 
 * Also contains some small utility functions for loading
 * these atlases, to make your life a lil bit easier.
 */
class FunkinSprite extends FlxAnimate {
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
}