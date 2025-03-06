package funkin.ui.slider;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class Slider extends UIComponent {
    public var value(default, set):Float = 0;
    public var min:Float = 0;
    public var max:Float = 1;
    public var step:Float = 0;
    
    public var callback:Float->Void;
    public var dragging:Bool = false;

    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        cursorType = POINTER;
    }

    //----------- [ Private API ] -----------//

    private var _lastThumbPos:FlxPoint = FlxPoint.get();

    private var _mousePos:FlxPoint = FlxPoint.get();
    private var _lastMousePos:FlxPoint = FlxPoint.get();

    private function _updateThumbPos(value:Float):Void {}

    override function destroy():Void {
        _lastThumbPos = FlxDestroyUtil.put(_lastThumbPos);

        _mousePos = FlxDestroyUtil.put(_mousePos);
        _lastMousePos = FlxDestroyUtil.put(_lastMousePos);

        super.destroy();
    }

    @:noCompletion
    private function set_value(newValue:Float):Float {
        if(dragging) // the slider itself will update the value while dragging
            return newValue;

        _updateThumbPos(newValue);
        return value = newValue;
    }
}