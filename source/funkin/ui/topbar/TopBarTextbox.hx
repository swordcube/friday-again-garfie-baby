package funkin.ui.topbar;

class TopBarTextbox extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var textbox:Textbox;

    public function new(x:Float = 0, y:Float = 0, text:String, ?autoSize:Bool = false, ?width:Float = 100) {
        super(x, y);

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
        add(bg);

        textbox = new Textbox(4, 4, text, autoSize, width, 22);
        add(textbox);

        bg.setGraphicSize(textbox.width + 16, bg.frameHeight);
        bg.updateHitbox();
    }
}