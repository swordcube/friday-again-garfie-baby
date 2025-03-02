package funkin.ui.panel;

import flixel.math.FlxRect;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;

// import flixel.addons.display.FlxSliceSprite;

class CustomPanel extends SliceSprite {
    public function new(x:Float = 0, y:Float = 0, graphic:FlxGraphicAsset, width:Float, height:Float) {
        var graphic:FlxGraphic = FlxG.bitmap.add(graphic);
        if(graphic == null)
            graphic = FlxG.bitmap.add(Paths.image("ui/images/panel"));
            
        super(x, y, graphic, FlxRect.get(5, 5, Std.int(graphic.width - 10), Std.int(graphic.height - 10)), width, height);
        // stretchTop = stretchBottom = stretchLeft = stretchRight = stretchCenter = true;
    }
}