package funkin.ui.credits;

import funkin.ui.AtlasText;

class CreditEntry extends FlxSpriteContainer {
    public var text:AtlasText;
    public var icon:FlxSprite;

    public function new(x:Float = 0, y:Float = 0, text:String, icon:String) {
        super();

        this.text = new AtlasText(100, 0, "bold", LEFT, text);
        add(this.text);

        final imgPath:String = Paths.image('menus/credits/icons/${icon}');
        this.icon = new FlxSprite(-20, -20).loadGraphic((FlxG.assets.exists(imgPath)) ? imgPath : Paths.image('menus/credits/icons/unknown'));
        this.icon.setGraphicSize(100, 100);
        this.icon.updateHitbox();
        add(this.icon);
    }
}