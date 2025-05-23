package funkin.ui;

class UIComponent extends FlxSpriteContainer implements IUIComponent {
    public var cursorType:CursorType = DEFAULT;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        UIUtil.allComponents.push(this);
    }

    public function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final ret:Bool = FlxG.mouse.overlaps(this, getDefaultCamera()) && UIUtil.allDropDowns.length == 0;
        _checkingMouseOverlap = false;
        return ret;
    }

    override function destroy():Void {
        UIUtil.allComponents.remove(this);

        if(UIUtil.focusedComponents.contains(this))
            UIUtil.focusedComponents.remove(this);

        super.destroy();
    }

    private var _checkingMouseOverlap:Bool = false;
}