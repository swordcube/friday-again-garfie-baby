package funkin.backend;

import openfl.display.Sprite;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

import flixel.FlxCamera;

/**
 * Shitty workaround for a flixel issue where shaders
 * can go outside of the flixel viewport
 * 
 * This happens because flixel's "viewport" isn't really
 * a viewport, and is just an OpenFL sprite with a scroll rect applied onto it
 */
class SideBars extends Sprite {
    public function new() {
        super();
        FlxG.cameras.cameraAdded.add(onCameraAdded);
    }

    public function onCameraAdded(camera:FlxCamera):Void {
        @:privateAccess
        FlxG.game.setChildIndex(this, FlxG.game.getChildIndex(FlxG.game._inputContainer) - 1);
    }

    override function __enterFrame(deltaTime:Float):Void {
        // i'm lazy so i'm using graphics api
        // instead of making bitmaps

        final leftWidth:Int = FlxMath.maxInt(Math.ceil(FlxG.game.x), 0);
        final rightWidth:Int = FlxMath.maxInt(Math.ceil(FlxG.stage.stageWidth - (FlxG.game.x + FlxG.scaleMode.gameSize.x)), 0);

        final topHeight:Int = FlxMath.maxInt(Math.ceil(FlxG.game.y), 0);
        final bottomHeight:Int = FlxMath.maxInt(Math.ceil(FlxG.stage.stageHeight - (FlxG.game.y + FlxG.scaleMode.gameSize.y)), 0);

        if(leftWidth == 0 && rightWidth == 0 && topHeight == 0 && bottomHeight == 0) {
            graphics.clear();
            return;
        }
        graphics.clear();
        graphics.beginFill(FlxG.stage.color);

        if(leftWidth != 0)
            graphics.drawRect(-FlxG.game.x, -FlxG.game.y, leftWidth, FlxG.stage.stageHeight);
        
        if(rightWidth != 0)
            graphics.drawRect(Math.ceil(FlxG.game.x + FlxG.scaleMode.gameSize.x) - FlxG.game.x, -FlxG.game.y, rightWidth, FlxG.stage.stageHeight);

        if(topHeight != 0)
            graphics.drawRect(-FlxG.game.x, -FlxG.game.y, FlxG.stage.stageWidth, topHeight);
        
        if(bottomHeight != 0)
            graphics.drawRect(-FlxG.game.x, Math.ceil(FlxG.game.y + FlxG.scaleMode.gameSize.y) - FlxG.game.y, FlxG.stage.stageWidth, bottomHeight);

        graphics.endFill();
    }
}