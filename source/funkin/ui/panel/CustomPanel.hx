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
        
        super(x, y, graphic);

        this.width = width;
        this.height = height;
    }
}