package funkin.ui.charter;

import flixel.math.FlxPoint;

import flixel.util.FlxAxes;
import flixel.util.FlxDestroyUtil;

import flixel.addons.display.FlxBackdrop;
import flixel.system.FlxAssets.FlxGraphicAsset;

import funkin.states.editors.ChartEditor;

class CharterGrid extends FlxBackdrop implements IUIComponent {
    public var parent:IUIComponent = null;
    public var cursorType:CursorType;
    public var charter(default, null):ChartEditor;

    public function new(?graphic:FlxGraphicAsset, ?repeatAxes:FlxAxes = XY, ?spacingX:Float = 0, ?spacingY:Float = 0) {
        super(graphic, repeatAxes, spacingX, spacingY);
        cursorType = CELL;

        charter = cast FlxG.state;
        UIUtil.allComponents.push(this);
    }

    override function update(elapsed:Float) {
        @:privateAccess
        if(!charter.objectGroup._movingObjects)
            cursorType = (charter.objectGroup.isHoveringNote || charter.objectGroup.isHoveringEvent) ? POINTER : CELL;
        else
            cursorType = GRABBING;
        
        super.update(elapsed);
    }

    public function checkMouseOverlap():Bool {
        if(_checkingMouseOverlap)
            return false; // prevent infinite recursion

        _checkingMouseOverlap = true;

        final pointer = TouchUtil.touch;
        pointer.getViewPosition(getDefaultCamera(), _mousePos);

        final v:Bool = _mousePos.x > x - (ChartEditor.CELL_SIZE * 2) && _mousePos.x < x + width && !UIUtil.isHoveringAnyComponent();
        _checkingMouseOverlap = false;
        return v;
    }

    override function destroy():Void {
        if(UIUtil.allComponents.contains(this))
            UIUtil.allComponents.remove(this);

        _mousePos = FlxDestroyUtil.put(_mousePos);
        super.destroy();
    }

    private var _checkingMouseOverlap:Bool = false;
    private var _mousePos:FlxPoint = FlxPoint.get();
}