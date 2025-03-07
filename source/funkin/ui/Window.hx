package funkin.ui;

import flixel.util.FlxTimer;

import funkin.ui.panel.*;

class Window extends UIComponent {
    public var bg:Panel;

    public var closeIcon:UISprite;
    public var collapseIcon:UISprite;

    public var separator:FlxSprite;
    public var contents:FlxSpriteContainer;

    public var closable:Bool = true;
    public var collapsable:Bool = true;

    public var collapsed:Bool = false;

    public function new(x:Float = 0, y:Float = 0, ?width:Float = 100, ?height:Float = 100) {
        super(x, y);

        bg = new Panel(0, 0, 1, 1);
        add(bg);

        closeIcon = new UISprite(12, 12, Paths.image("ui/images/window/close"));
        closeIcon.cursorType = POINTER;
        add(closeIcon);

        collapseIcon = new UISprite(12, 12, Paths.image("ui/images/window/collapse"));
        collapseIcon.cursorType = POINTER;
        add(collapseIcon);

        separator = new FlxSprite(4, 36).loadGraphic(Paths.image("ui/images/separator"));
        add(separator);

        contents = new FlxSpriteContainer(4, 38);
        add(contents);

        this.width = width ?? 100;
        this.height = height ?? 100;
    }

    override function update(elapsed:Float) {
        var totalShit:Float = 0;
        for(icon in [closeIcon, collapseIcon]) {
            if(!icon.visible)
                continue;
            
            totalShit += icon.width + 16;
            icon.x = bg.x + (bg.width - totalShit);
        }
        if(closeIcon.visible && closeIcon.checkMouseOverlap() && FlxG.mouse.justReleased)
            FlxTimer.wait(0.001, () -> destroy());

        super.update(elapsed);
    }

    override function set_width(Value:Float):Float {
        if(bg != null) {
            var totalShit:Float = 0;
            for(icon in [closeIcon, collapseIcon]) {
                if(!icon.visible)
                    continue;
                
                totalShit += icon.width + 16;
                icon.x = bg.x + (Value - totalShit);
            }
            bg.width = Value;
            
            separator.setGraphicSize(Value - 8, separator.frameHeight);
            separator.updateHitbox();
        }
        return width = Value;
    }
    
    override function set_height(Value:Float):Float {
        if(bg != null) {
            bg.height = Value;
        }
        return height = Value;
    }
}