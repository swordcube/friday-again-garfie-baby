package funkin.ui.slider;

class HorizontalSlider extends Slider {
    public var leftSide:FlxSprite;
    public var middle:FlxSprite;
    public var rightSide:FlxSprite;

    public var thumb:FlxSprite; // til that this is called a thumb (or handle, thumb sounds funnier)

    public function new(x:Float = 0, y:Float = 0, width:Float = 17) {
        super(x, y);

        leftSide = new FlxSprite().loadGraphic(Paths.image("ui/images/horizontal_slider_bg"), true, 6, 10);
        leftSide.frame = leftSide.frames.frames[0];
        add(leftSide);

        middle = new FlxSprite().loadGraphic(Paths.image("ui/images/horizontal_slider_bg"), true, 6, 10);
        middle.frame = middle.frames.frames[1];
        add(middle);

        rightSide = new FlxSprite().loadGraphic(Paths.image("ui/images/horizontal_slider_bg"), true, 6, 10);
        rightSide.frame = rightSide.frames.frames[2];
        add(rightSide);

        thumb = new FlxSprite(-1).loadGraphic(Paths.image("ui/images/slider_thumb"), true, 18, 18);
        thumb.frame = thumb.frames.frames[0];
        thumb.y = leftSide.y - (leftSide.height * 0.5);
        add(thumb);

        this.width = width;
    }

    override function set_width(newWidth:Float):Float {
        if(leftSide != null) {
            middle.x = leftSide.x + leftSide.width;
    
            middle.setGraphicSize(Math.max(newWidth - leftSide.width - rightSide.width, 0), middle.frameHeight);
            middle.updateHitbox();
    
            rightSide.x = middle.x + middle.width;
        }
        return width = newWidth;
    }
}