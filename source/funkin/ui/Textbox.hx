package funkin.ui;

import flixel.text.FlxText;

// TODO: add multiline functionality

class Textbox extends UIComponent {
    public var bg:SliceSprite;
    public var label:FlxText;

    public var text(get, set):String;
    public var pressed:Bool = false;

    public var autoSize:Bool = false;

    public function new(x:Float = 0, y:Float = 0, text:String, ?autoSize:Bool = false, ?width:Float = 100, ?height:Float = 26) {
        super(x, y);

        bg = new SliceSprite(0, 0);
        bg.loadGraphic(Paths.image("ui/images/panel"));
        add(bg);

        label = new FlxText(8, 0, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        label.y = bg.y + ((bg.height - label.height) * 0.5);
        add(label);

        this.autoSize = autoSize;

        this.width = width;
        this.height = height;

        this.text = text;
    }

    override function update(elapsed:Float) {
        if(FlxG.mouse.overlaps(bg)) {

        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    override function set_width(Value:Float):Float {
        if(autoSize)
            return Value;

        bg.width = Value;
        return width = Value;
    }

    override function set_height(Value:Float):Float {
        if(autoSize)
            return Value;

        bg.height = Value;
        return height = Value;
    }
    
    @:noCompletion
    private inline function get_text():String {
        return label.text;
    }

    @:noCompletion
    private inline function set_text(Value:String):String {
        label.text = Value;
        label.setPosition(bg.x + ((bg.width - label.width) * 0.5), bg.y + ((bg.height - label.height) * 0.5));
        return Value;
    }
}