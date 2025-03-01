package funkin.ui.topbar;

import flixel.text.FlxText;

class TopBarButton extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var label:FlxText;
    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, callback:Void->Void) {
        super(x, y);

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
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
        var offset:Float = (isHovered()) ? (FlxG.mouse.pressed ? -15 : 15) : 0;
        bg.colorTransform.redOffset = FlxMath.lerp(bg.colorTransform.redOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));
        bg.colorTransform.greenOffset = FlxMath.lerp(bg.colorTransform.greenOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));
        bg.colorTransform.blueOffset = FlxMath.lerp(bg.colorTransform.blueOffset, offset, FlxMath.getElapsedLerp(0.32, elapsed));

        if(isHovered() && FlxG.mouse.justPressed) {
            if(callback != null)
                callback();
        }
        super.update(elapsed);
    }

    public function isHovered():Bool {
        return FlxG.mouse.overlaps(bg, bg.getDefaultCamera());
    }
}