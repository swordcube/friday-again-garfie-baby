package funkin.backend.plugins;

import haxe.io.Path;

import sys.io.File;
import sys.FileSystem;

import openfl.events.MouseEvent;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;

import funkin.utilities.FileUtil;
import funkin.utilities.MemoryUtil;

/**
 * A basic screenshotting tool, press F3 to activate it
 */
class ScreenShotPlugin extends FlxBasic {
    public static var tweenManager:FlxTweenManager;
    public static var previews:Array<ScreenShotPreview> = [];

    /**
     * Initializes the screenshotting tool.
     */
    public function new() {
        super();

        tweenManager = new FlxTweenManager();
        FlxG.signals.preStateSwitch.remove(tweenManager.clear);
    }

    override function update(elapsed:Float) {
        tweenManager.update(elapsed);
        
        if(Controls.instance.justPressed.SCREENSHOT) {
            var bitmap = BitmapData.fromImage(FlxG.stage.window.readPixels());
            var preview = new ScreenShotPreview(bitmap);
            Main.instance.addChildAt(preview, Main.instance.getChildIndex(Main.statsDisplay));
        }
        if(previews.length == 0 && FlxG.mouse.cursorContainer.visible && !FlxG.mouse.visible) {
            @:privateAccess
            FlxG.mouse.hideCursor();
        }
    }

    //----------- [ Private API ] -----------//

    private var _container:Sprite;
}

class ScreenShotPreview extends Sprite {
    public var hovering:Bool = false;
    public var imagePath:String;

    public function new(bitmapData:BitmapData) {
        super();
        buttonMode = true;

        bitmap = new Bitmap(bitmapData, null, true);
        bitmap.scaleX = bitmap.scaleY = 0.3;
        addChild(bitmap);

        // setup image path & folder
        var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
        imagePath = './screenshots/screenshot-${dateNow}.png';

        if(!FileSystem.exists("./screenshots"))
            FileSystem.createDirectory("./screenshots");

        // position the shit
        y -= 10;
        alpha = 0.001;

        // tween the shit in and out
        ScreenShotPlugin.tweenManager.tween(this, {alpha: 1, y: 0}, 0.5, {ease: FlxEase.cubeOut});
        tweenOut();

        // flash bang
        var flashBitmap = new Bitmap(new BitmapData(1, 1, false, 0xFFFFFFFF));
        flashBitmap.scaleX = FlxG.stage.stageWidth;
        flashBitmap.scaleY = FlxG.stage.stageHeight;
        Main.instance.addChildAt(flashBitmap, Main.instance.getChildIndex(Main.statsDisplay));
        ScreenShotPlugin.tweenManager.tween(flashBitmap, {alpha: 0}, 0.15, {ease: FlxEase.quadOut, onComplete: (_) -> Main.instance.removeChild(flashBitmap)});

        // mouse events :D
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        // save the file to disk
        File.saveBytes(imagePath, bitmapData.encode(bitmapData.rect, new PNGEncoderOptions()));

        // play fumny camera sound
        FlxG.sound.play(Paths.sound("ui/sfx/screenshot"));

        // force the cursor to show up
        if(!FlxG.mouse.visible) {
            @:privateAccess
            FlxG.mouse.showCursor();
        }
        ScreenShotPlugin.previews.push(this);
    }

    public function tweenOut():Void {
        ScreenShotPlugin.tweenManager.tween(this, {alpha: 0, y: y + 20}, 0.5, {ease: FlxEase.cubeOut, startDelay: 3, onComplete: (_) -> {
            @:privateAccess {
                if(bitmap.bitmapData.__texture != null)
                    bitmap.bitmapData.__texture.dispose();
            }
            bitmap.bitmapData.disposeImage();
            bitmap.bitmapData.dispose();
            parent.removeChild(this);

            ScreenShotPlugin.previews.remove(this);
            MemoryUtil.clearAll();
        }});
    }

    // --------------- //
    // [ Private API ] //
    // --------------- //

    private var bitmap:Bitmap;

    override function __enterFrame(deltaTime:Float):Void {
        alpha = FlxMath.lerp(alpha, (hovering) ? 0.6 : 1, FlxMath.getElapsedLerp(0.35, deltaTime / 1000));
        super.__enterFrame(deltaTime);
    }

    private function onMouseUp(e:MouseEvent):Void {
        FileUtil.openFolder(Path.directory(FileSystem.fullPath(imagePath)));
    }

    private function onMouseOver(e:MouseEvent):Void {
        hovering = true;
    }

    private function onMouseOut(e:MouseEvent):Void {
        hovering = false;
    }
}