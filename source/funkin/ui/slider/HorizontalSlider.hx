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

    override function update(elapsed:Float) {
        final thumbHovered:Bool = FlxG.mouse.overlaps(thumb);
        thumb.frame = thumb.frames.frames[(thumbHovered || dragging) ? 1 : 0];

        if(FlxG.mouse.overlaps(this) && FlxG.mouse.pressed && !dragging) {
            dragging = true;

            final thumbPosCap = width - (thumb.width - 1);
            _lastThumbPos.x = FlxMath.bound(((thumbHovered) ? thumb.x : (FlxG.mouse.x - ((thumb.width + 1) * 0.5))) - x, 0, thumbPosCap) + 1;
            FlxG.mouse.getWorldPosition(getDefaultCamera(), _lastMousePos);
        }
        else if(dragging && FlxG.mouse.justReleased)
            dragging = false;

        if(dragging) {
            final thumbPosCap:Float = width - (thumb.width - 1);
            FlxG.mouse.getWorldPosition(getDefaultCamera(), _mousePos);
        
            final oldValue:Float = value;
            final newValue:Float = FlxMath.remapToRange(FlxMath.bound((_lastThumbPos.x + (FlxG.mouse.x - _lastMousePos.x)) / thumbPosCap, 0, 1), 0, 1, min, max);
        
            @:bypassAccessor value = (step > 0) ? Math.floor(newValue / step) * step : newValue;
            if(value != oldValue && callback != null)
                callback(value);

            _updateThumbPos(value);
        }
        super.update(elapsed);
    }

    override function _updateThumbPos(value:Float):Void {
        final thumbPosCap = width - (thumb.width - 1);
        final percent = FlxMath.remapToRange(value, min, max, 0, 1);
        thumb.x = x + FlxMath.lerp(0, thumbPosCap, percent) - 1;
    }

    override function set_width(newWidth:Float):Float {
        if(newWidth < 20)
            newWidth = 20; // you can't make the slider smaller than the thumb

        if(leftSide != null) {
            middle.x = leftSide.x + leftSide.width;
    
            middle.setGraphicSize(Math.max(newWidth - leftSide.width - rightSide.width, 0), middle.frameHeight);
            middle.updateHitbox();
    
            rightSide.x = middle.x + middle.width;
        }
        return width = newWidth;
    }
}