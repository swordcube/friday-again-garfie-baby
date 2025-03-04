package funkin.ui;

class UIComponent extends FlxSpriteContainer {
    public static final allComponents:Array<UIComponent> = [];

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        allComponents.push(this);
    }

    public static function isHoveringAny():Bool {
        var c:UIComponent = null;
        for(i in 0...allComponents.length) {
            c = allComponents[i];
            if(FlxG.mouse.overlaps(c, c.getDefaultCamera()))
                return true;
        }
        return false;
    }

    override function destroy():Void {
        allComponents.remove(this);
        super.destroy();
    }
}