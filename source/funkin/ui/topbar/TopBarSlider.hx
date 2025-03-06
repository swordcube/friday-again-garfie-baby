package funkin.ui.topbar;

import flixel.text.FlxText;
import funkin.ui.slider.HorizontalSlider;

class TopBarSlider extends FlxSpriteContainer {
    public var bg:FlxSprite;
    public var slider:HorizontalSlider;
    public var valueFactory:Void->Float;

    public function new(x:Float = 0, y:Float = 0, min:Float, max:Float, step:Float, value:Float, width:Float, ?callback:Float->Void, ?valueFactory:Void->Float) {
        super(x, y);

        bg = new FlxSprite().loadGraphic(Paths.image("ui/images/top_bar"));
        add(bg);

        slider = new HorizontalSlider(8, 0, width);
        slider.min = min;
        slider.max = max;
        slider.step = step;
        slider.value = value;
        slider.callback = callback;
        slider.y = bg.y + ((bg.height - slider.middle.height) * 0.5);
        add(slider);

        bg.setGraphicSize(slider.width + 16, bg.frameHeight);
        bg.updateHitbox();

        this.valueFactory = valueFactory;
    }

    override function update(elapsed:Float):Void {
        if(valueFactory != null)
            slider.value = valueFactory();

        super.update(elapsed);
    }
}