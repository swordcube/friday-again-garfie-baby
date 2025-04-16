package funkin.ui.topbar;

import flixel.text.FlxText;

using flixel.util.FlxColorTransformUtil;

class TopBarButton extends UIComponent {
    public var bg:FlxSprite;
    public var label:FlxText;
    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, callback:Void->Void) {
        super(x, y);
        cursorType = POINTER;

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
        bg.visible = false;
        add(bg);

        label = new FlxText(8, 0, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        label.y = bg.y + ((bg.height - label.height) * 0.5);
        add(label);

        bg.setGraphicSize(label.width + 16, bg.frameHeight);
        bg.updateHitbox();

        this.callback = callback;
    }

    override function update(elapsed:Float):Void {
        final isHovered:Bool = checkMouseOverlap();
        final offset:Float = (isHovered) ? (FlxG.mouse.pressed ? -15 : 15) : 0;
        
        bg.colorTransform.redOffset = FlxMath.lerp(bg.colorTransform.redOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));
        if(Math.abs(bg.colorTransform.redOffset) < 0.001)
            bg.colorTransform.redOffset = 0;

        bg.colorTransform.greenOffset = FlxMath.lerp(bg.colorTransform.greenOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));
        if(Math.abs(bg.colorTransform.greenOffset) < 0.001)
            bg.colorTransform.greenOffset = 0;

        bg.colorTransform.blueOffset = FlxMath.lerp(bg.colorTransform.blueOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));
        if(Math.abs(bg.colorTransform.blueOffset) < 0.001)
            bg.colorTransform.blueOffset = 0;

        bg.visible = bg.colorTransform.hasRGBOffsets();

        if(isHovered && FlxG.mouse.justReleased) {
            if(callback != null)
                callback();
        }
        super.update(elapsed);
    }

    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final ret:Bool = FlxG.mouse.overlaps(bg, bg.getDefaultCamera());
        _checkingMouseOverlap = false;
        return ret;
    }
}