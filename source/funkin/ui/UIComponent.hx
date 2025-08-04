package funkin.ui;

class UIComponent extends FlxSpriteContainer implements IUIComponent {
    public var parent:IUIComponent = null;
    public var cursorType:CursorType = DEFAULT;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        UIUtil.allComponents.push(this);

        group.memberAdded.add((m) -> {
            if(m is IUIComponent)
                cast(m, IUIComponent).parent = this;
        });
        group.memberRemoved.add((m) -> {
            if(m is IUIComponent)
                cast(m, IUIComponent).parent = null;
        });
    }

    public function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final pointer = TouchUtil.touch;
        final ret:Bool = pointer.overlaps(this, getDefaultCamera()) && UIUtil.allDropDowns.length == 0;
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