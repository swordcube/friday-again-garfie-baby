package funkin.ui;

class Checkbox extends UIComponent {
    public var box:FlxSprite;
    public var label:Label;

    public var text(get, set):String;
    public var checked:Bool;

    public var pressed:Bool = false;
    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, ?checked:Bool = false) {
        super(x, y);
        cursorType = POINTER;

        box = new FlxSprite(0, 0);
        box.loadGraphic(Paths.image("ui/images/checkbox"), true, 24, 24);
        add(box);

        label = new Label(box.width + 5, 2, text ?? "");
        add(label);

        this.checked = checked;
    }

    override function update(elapsed:Float):Void {
        final frameOffset:Int = (checked) ? 3 : 0;
        if(checkMouseOverlap()) {
            if(TouchUtil.justPressed && !pressed)
                pressed = true;

            if(TouchUtil.justReleased && pressed) {
                checked = !checked;
                if(callback != null)
                    callback();

                pressed = false;
            }
            box.frame = (pressed) ? box.frames.frames[frameOffset + 2] : box.frames.frames[frameOffset + 1];
        }
        else
            box.frame = box.frames.frames[frameOffset];

        super.update(elapsed);
    }
    
    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final pointer = TouchUtil.touch;
        final ret:Bool = (pointer.overlaps(box, getDefaultCamera()) || pointer.overlaps(label, getDefaultCamera())) && UIUtil.allDropDowns.length == 0;
        _checkingMouseOverlap = false;
        return ret;
    }

    @:noCompletion
    private inline function get_text():String {
        return label.text;
    }

    @:noCompletion
    private inline function set_text(Value:String):String {
        Value ??= "";

        label.text = Value;
        label.visible = (Value != null && Value.length != 0);

        return Value;
    }
}