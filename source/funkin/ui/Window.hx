package funkin.ui;

import flixel.math.FlxPoint;

import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

import funkin.ui.panel.*;

class Window extends UIComponent {
    public var bg:Panel;

    public var titleBar:FlxSprite;
    public var titleLabel:Label;

    public var closeIcon:UISprite;
    public var collapseIcon:UISprite;

    public var separator:FlxSprite;
    public var contents:FlxSpriteContainer;

    public var closable:Bool = true;
    
    /**
     * Whether or not the window should be destroyed when it is closed.
     * If this is disabled, it will be killed instead.
     */
    public var destructivelyClose:Bool = true;

    public var collapsable:Bool = true;

    public var onClose:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public var collapsed:Bool = false;

    public var autoSize:Bool = false;
    public var dragging:Bool = false;

    public function new(x:Float = 0, y:Float = 0, ?title:String, ?autoSize:Bool = false, ?width:Float = 100, ?height:Float = 100) {
        super(x, y);

        bg = new Panel(0, 0, 1, 1);
        add(bg);

        titleBar = new FlxSprite().makeSolid(32, 32, FlxColor.BLUE);
        titleBar.kill();
        add(titleBar);

        titleLabel = new Label(10, 6, title ?? "");
        add(titleLabel);

        closeIcon = new UISprite(10, 10, Paths.image("ui/images/window/close"));
        closeIcon.cursorType = POINTER;
        add(closeIcon);

        collapseIcon = new UISprite(10, 10, Paths.image("ui/images/window/collapse"));
        collapseIcon.cursorType = POINTER;
        add(collapseIcon);

        separator = new FlxSprite(4, 32).loadGraphic(Paths.image("ui/images/separator"));
        separator.antialiasing = false;
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
        final pointer = TouchUtil.touch;
        if(closeIcon.visible && closeIcon.checkMouseOverlap() && TouchUtil.justReleased)
            FlxTimer.wait(0.001, close);

        if(TouchUtil.justPressed && pointer.overlaps(titleBar, getDefaultCamera())) {
            _lastPos.set(x, y);
            pointer.getViewPosition(getDefaultCamera(), _lastMousePos);
            dragging = true;
        }
        if(dragging && TouchUtil.justReleased)
            dragging = false;

        if(dragging && TouchUtil.pressed && TouchUtil.justMoved) {
            pointer.getViewPosition(getDefaultCamera(), _mousePos);
            x = _lastPos.x + (_mousePos.x - _lastMousePos.x);
            y = _lastPos.y + (_mousePos.y - _lastMousePos.y);
        }
        super.update(elapsed);
    }

    public function show():Void {
        @:bypassAccessor exists = true;
    }

    public function hide():Void {
        @:bypassAccessor exists = false;
    }

    public function close():Void {
        if(destructivelyClose)
            destroy();
        else {
            onClose.dispatch();
            hide();
        }
    }
    
    override function destroy():Void {
        _lastPos = FlxDestroyUtil.put(_lastPos);
        _mousePos = FlxDestroyUtil.put(_mousePos);
        _lastMousePos = FlxDestroyUtil.put(_lastMousePos);

        onClose.dispatch();
        super.destroy();
    }

    private var _lastPos:FlxPoint = FlxPoint.get();
    private var _mousePos:FlxPoint = FlxPoint.get();
    private var _lastMousePos:FlxPoint = FlxPoint.get();

    private var _pendingComponents:Array<FlxSprite> = [];

    #if FLX_TOUCH
    private
    #end

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
            
            titleBar.setGraphicSize(Value, 32);
            titleBar.updateHitbox();

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