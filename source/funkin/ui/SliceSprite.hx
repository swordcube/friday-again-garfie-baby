package funkin.ui;

import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;

class SliceSprite extends FlxSprite {
    public var sliceRect:FlxRect;

    public function new(x:Float = 0, y:Float = 0, graphic:FlxGraphicAsset, sliceRect:FlxRect, width:Float, height:Float) {
        super(x, y, graphic);
        this.sliceRect = sliceRect;

        this.width = width;
        this.height = height;
    }

    override function draw():Void {
        
    }

    override function set_width(newWidth:Float):Float {
        return width = newWidth;
    }

    override function set_height(newHeight:Float):Float {
        return height = newHeight;
    }

    override function destroy():Void {
        sliceRect = FlxDestroyUtil.put(sliceRect);
        super.destroy();
    }
}