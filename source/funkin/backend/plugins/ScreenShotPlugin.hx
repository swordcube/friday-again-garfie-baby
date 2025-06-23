package funkin.backend.plugins;

import haxe.io.Path;

import sys.io.File;
import sys.FileSystem;

import sys.thread.Deque;
import sys.thread.Thread;

import lime.graphics.Image;
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

        Thread.create(_screenshotWorker_loop);
    }

    override function update(elapsed:Float) {
        tweenManager.update(elapsed);
        
        if(Controls.instance.justPressed.SCREENSHOT)
            _messageQueue.push(FlxG.stage.window.readPixels());

        final p:ScreenShotPreview = _previewQueue.pop(false);
        if(p != null) {
            p.create();
            Main.instance.addChildAt(p, Main.instance.getChildIndex(Main.statsDisplay));
        }
        if(previews.length == 0 && FlxG.mouse.cursorContainer.visible && !FlxG.mouse.visible) {
            @:privateAccess
            FlxG.mouse.hideCursor();
        }
    }

    override function destroy():Void {
        super.destroy();
        _messageQueue.push(null);
    }

    //----------- [ Private API ] -----------//

    private var _container:Sprite;
    
    // some operations are very slow so we're offloading them to a separate thread.
	// we use this deque to send screenshot pixels to be processed by the thread.
	private var _messageQueue: Deque<Image> = new Deque();
	private var _previewQueue: Deque<ScreenShotPreview> = new Deque();

    private function _screenshotWorker_loop(): Void {
		while(true) {
			final pixels: Image = _messageQueue.pop(true);
			if(pixels == null) {
				// we told the thread to stop, so break the loop.
				break;
			}
            // generate bitmapdata from the pixels
            final bitmap = BitmapData.fromImage(pixels);

            // setup image path & folder
            final dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
            final imagePath:String = './screenshots/screenshot-${dateNow}.png';

            // create the in-game preview
            var preview = new ScreenShotPreview(bitmap);
            preview.imagePath = imagePath;
            _previewQueue.push(preview);
            
            // save the file to disk
            if(!FileSystem.exists("./screenshots"))
                FileSystem.createDirectory("./screenshots");
            
            File.saveBytes(imagePath, bitmap.encode(bitmap.rect, new PNGEncoderOptions()));
        }
    }
}

class ScreenShotPreview extends Sprite {
    public var hovering:Bool = false;
    public var imagePath:String;

    public function new(bitmapData:BitmapData) {
        super();
        this.bitmapData = bitmapData;
        buttonMode = true;
    }

    public function create():Void {
        bitmap = new Bitmap(bitmapData, null, true);
        bitmap.scaleX = bitmap.scaleY = 0.3;
        addChild(bitmap);

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
        ScreenShotPlugin.tweenManager.tween(flashBitmap, {alpha: 0}, 0.15, {ease: FlxEase.quadOut, onComplete: (_) -> {
            @:privateAccess {
                if(flashBitmap.bitmapData.__texture != null)
                    flashBitmap.bitmapData.__texture.dispose();
            }
            flashBitmap.bitmapData.disposeImage();
            flashBitmap.bitmapData.dispose();

            Main.instance.removeChild(flashBitmap);
        }});

        // mouse events :D
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

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
    private var bitmapData:BitmapData;

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