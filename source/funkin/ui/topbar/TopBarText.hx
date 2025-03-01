package funkin.ui.topbar;

import flixel.text.FlxText;

class TopBarText extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var label:FlxText;

    public function new(x:Float = 0, y:Float = 0, text:String) {
        super(x, y);

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
        add(bg);

        label = new FlxText(8, 0, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        label.y = bg.y + ((bg.height - label.height) * 0.5);
        add(label);

        bg.setGraphicSize(label.width + 16, bg.frameHeight);
        bg.updateHitbox();
    }
}