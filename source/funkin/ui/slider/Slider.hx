package funkin.ui.slider;

class Slider extends FlxSpriteContainer {
    public var value:Float = 0;
    public var min:Float = 0;
    public var max:Float = 1;
    public var step:Float = 0.25;
    public var callback:Float->Void;
}