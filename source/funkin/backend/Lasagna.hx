package funkin.backend;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

class Lasagna extends Bitmap {
    public function new() {
        super();
        bitmapData = FlxG.assets.getBitmapData(Paths.image("lasagna-with-meat-sauce-and-chee"));
        
        FlxG.signals.gameResized.add(onGameResize);
        onGameResize(FlxG.stage.stageWidth, FlxG.stage.stageHeight);

        visible = Options.lasagna;
    }

    public function onGameResize(width:Int, height:Int):Void {
        x = (width - this.width) * 0.5;
        y = (height - this.height) * 0.5;
    }

    override function __enterFrame(dt:Float):Void {
        super.__enterFrame(dt);
        visible = Options.lasagna;
    }
}