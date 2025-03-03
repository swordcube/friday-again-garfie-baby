package funkin.ui.charter;

import funkin.ui.slider.HorizontalSlider;

import funkin.states.editors.ChartEditor;

class CharterPlayBar extends FlxSpriteContainer {
    public var charter(default, null):ChartEditor;

    public var bg:FlxSprite;
    public var songSlider:HorizontalSlider;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        charter = cast FlxG.state;

        bg = new FlxSprite(0, 0).loadGraphic(Paths.image("ui/images/bottom_bar_big"));
        bg.setGraphicSize(FlxG.width, bg.frameHeight);
        bg.updateHitbox();
        add(bg);

        songSlider = new HorizontalSlider(0, 0, FlxG.width);
        songSlider.y = bg.y - songSlider.middle.height;
        add(songSlider);
    }
}