package funkin.ui;

import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;

import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxImageFrame;

@:access(flixel.graphics.frames.FlxFrame)
class Button extends UIComponent {
    public var bg:SliceSprite;
    public var label:FlxText;

    public var text(get, set):String;

    public var pressed:Bool = false;
    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, ?width:Float = 0, ?height:Float = 0, ?callback:Void->Void) {
        super(x, y);

        bg = new SliceSprite(0, 0);
        bg.loadGraphic(Paths.image("ui/images/button"), true, 48, 48);
        add(bg);

        label = new FlxText(8, 0, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        label.y = bg.y + ((bg.height - label.height) * 0.5);
        add(label);

        this.width = width;
        this.height = height;

        this.callback = callback;
    }

    override function update(elapsed:Float) {
        if(FlxG.mouse.overlaps(bg)) {
            if(FlxG.mouse.justPressed && !pressed)
                pressed = true;

            if(FlxG.mouse.justReleased && pressed) {
                if(callback != null)
                    callback();

                pressed = false;
            }
            bg.frame = (pressed) ? bg.frames.frames[2] : bg.frames.frames[1];
        }
        else
            bg.frame = bg.frames.frames[0];
        
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    override function set_width(Value:Float):Float {
        if(bg != null) {
            if(Value <= 0)
                bg.width = label.width + 16;
            else
                bg.width = Value;

            label.setPosition(bg.x + ((bg.width - label.width) * 0.5), bg.y + ((bg.height - label.height) * 0.5));
        }
        return width = Value;
    }

    override function set_height(Value:Float):Float {
        if(bg != null) {
            if(Value <= 0)
                bg.height = label.height + 8;
            else
                bg.height = Value;

            label.setPosition(bg.x + ((bg.width - label.width) * 0.5), bg.y + ((bg.height - label.height) * 0.5));
        }
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