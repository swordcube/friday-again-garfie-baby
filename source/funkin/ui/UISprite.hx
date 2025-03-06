package funkin.ui;

import flixel.system.FlxAssets.FlxGraphicAsset;

class UISprite extends FlxSprite implements IUIComponent {
    public var cursorType:CursorType = DEFAULT;

    public function new(x:Float = 0, y:Float = 0, ?graphic:FlxGraphicAsset) {
        super(x, y, graphic);
        UIUtil.allComponents.push(this);
    }

    override function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):UISprite {
        return cast super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    }

    override function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):UISprite {
        return cast super.makeGraphic(width, height, color, unique, key);
    }

    override function makeSolid(width:Float, height:Float, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):UISprite {
        return cast super.makeSolid(width, height, color, unique, key);
    }

    public function checkMouseOverlap():Bool {
        return FlxG.mouse.overlaps(this, getDefaultCamera());
    }

    override function destroy():Void {
        if(UIUtil.allComponents.contains(this))
            UIUtil.allComponents.remove(this);
        
        super.destroy();
    }
}