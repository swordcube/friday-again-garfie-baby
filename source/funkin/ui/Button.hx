package funkin.ui;

import flixel.text.FlxText;

class Button extends UIComponent {
    public var bg:SliceSprite;
    
    public var label:FlxText;
    public var text(get, set):String;

    public var icon(default, set):String;
    public var iconSpr:FlxSprite;

    public var contentContainer:FlxSpriteContainer;

    public var pressed:Bool = false;
    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, ?width:Float = 0, ?height:Float = 0, ?callback:Void->Void) {
        super(x, y);
        cursorType = POINTER;

        bg = new SliceSprite(0, 0);
        bg.loadGraphic(Paths.image("ui/images/button"), true, 48, 48);
        add(bg);

        contentContainer = new FlxSpriteContainer(0, 0);
        add(contentContainer);

        iconSpr = new FlxSprite(0, 0);
        iconSpr.visible = false;
        contentContainer.add(iconSpr);
        
        label = new FlxText(0, 0, 0, text ?? "");
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        contentContainer.add(label);

        this.width = width;
        this.height = height;

        this.callback = callback;
    }

    override function update(elapsed:Float):Void {
        if(checkMouseOverlap()) {
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

    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final ret:Bool = FlxG.mouse.overlaps(bg, getDefaultCamera()) && !UIUtil.isHoveringAnyComponent([this, bg]);
        _checkingMouseOverlap = false;
        return ret;
    }

    //----------- [ Private API ] -----------//

    override function set_width(Value:Float):Float {
        if(bg != null) {
            if(Value <= 0)
                bg.width = contentContainer.width + 16;
            else
                bg.width = Value;

            contentContainer.setPosition(bg.x + ((bg.width - contentContainer.width) * 0.5), bg.y + ((bg.height - contentContainer.height) * 0.5));
        }
        return width = Value;
    }

    override function set_height(Value:Float):Float {
        if(bg != null) {
            if(Value <= 0)
                bg.height = contentContainer.height + 2;
            else
                bg.height = Value;

            contentContainer.setPosition(bg.x + ((bg.width - contentContainer.width) * 0.5), bg.y + ((bg.height - contentContainer.height) * 0.5));
        }
        return height = Value;
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
        
        contentContainer.setPosition(bg.x + ((bg.width - contentContainer.width) * 0.5), bg.y + ((bg.height - contentContainer.height) * 0.5));
        return Value;
    }
    
    @:noCompletion
    private inline function set_icon(newIcon:String):String {
        if(newIcon != null && newIcon.length != 0) {
            iconSpr.visible = true;
            iconSpr.loadGraphic(newIcon);
            iconSpr.updateHitbox();
            
            if(label.text.length != 0)
                label.x = iconSpr.x + iconSpr.width + 4;
            else
                label.x = iconSpr.x;
        }
        else {
            iconSpr.visible = false;
        }
        contentContainer.setPosition(bg.x + ((bg.width - contentContainer.width) * 0.5), bg.y + ((bg.height - contentContainer.height) * 0.5));
        
        iconSpr.y = bg.y + ((bg.height - iconSpr.height) * 0.5);
        label.y = bg.y + ((bg.height - label.height) * 0.5);

        return icon = newIcon;
    }
}