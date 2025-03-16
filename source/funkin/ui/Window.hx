package funkin.ui;

import flixel.util.FlxTimer;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.ui.panel.*;

class Window extends UIComponent {
    public var bg:Panel;
    public var titleLabel:Label;

    public var closeIcon:UISprite;
    public var collapseIcon:UISprite;

    public var separator:FlxSprite;
    public var contents:FlxSpriteContainer;

    public var closable:Bool = true;
    public var collapsable:Bool = true;

    public var onClose:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var collapsed:Bool = false;

    public var autoSize:Bool = false;

    public function new(x:Float = 0, y:Float = 0, ?title:String, ?autoSize:Bool = false, ?width:Float = 100, ?height:Float = 100) {
        super(x, y);

        bg = new Panel(0, 0, 1, 1);
        add(bg);

        titleLabel = new Label(10, 6, title ?? "");
        add(titleLabel);

        closeIcon = new UISprite(10, 10, Paths.image("ui/images/window/close"));
        closeIcon.cursorType = POINTER;
        add(closeIcon);

        collapseIcon = new UISprite(10, 10, Paths.image("ui/images/window/collapse"));
        collapseIcon.cursorType = POINTER;
        add(collapseIcon);

        separator = new FlxSprite(4, 32).loadGraphic(Paths.image("ui/images/separator"));
        add(separator);

        contents = new FlxSpriteContainer(4, 34);
        add(contents);

        this.autoSize = autoSize ?? false;
        initContents();

        for(c in _pendingComponents)
            contents.add(c);

        this.width = width ?? (this.autoSize ? contents.width + 4 : 100);
        this.height = height ?? (this.autoSize ? contents.height + 36 : 100);
    }

    public function addToContents(spr:FlxSprite):Void {
        _pendingComponents.push(spr);
    }

    public function initContents():Void {}

    override function update(elapsed:Float) {
        var totalShit:Float = 0;
        for(icon in [closeIcon, collapseIcon]) {
            if(!icon.visible)
                continue;
            
            totalShit += icon.width + 14;
            icon.x = bg.x + (bg.width - totalShit) + 4;
        }
        if(closeIcon.visible && closeIcon.checkMouseOverlap() && FlxG.mouse.justReleased)
            FlxTimer.wait(0.001, close);

        super.update(elapsed);
    }

    public function close():Void {
        onClose.dispatch();
        destroy();
    }

    private var _pendingComponents:Array<FlxSprite> = [];

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