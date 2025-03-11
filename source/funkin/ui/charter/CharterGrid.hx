package funkin.ui.charter;

import flixel.math.FlxPoint;

import flixel.util.FlxAxes;
import flixel.util.FlxDestroyUtil;

import flixel.addons.display.FlxBackdrop;
import flixel.system.FlxAssets.FlxGraphicAsset;

import funkin.states.editors.ChartEditor;

class CharterGrid extends FlxBackdrop implements IUIComponent {
    public var cursorType:CursorType;
    public var charter(default, null):ChartEditor;

    public function new(?graphic:FlxGraphicAsset, ?repeatAxes:FlxAxes = XY, ?spacingX:Float = 0, ?spacingY:Float = 0) {
        super(graphic, repeatAxes, spacingX, spacingY);
        cursorType = CELL;

        charter = cast FlxG.state;
        UIUtil.allComponents.push(this);
    }

    public function checkMouseOverlap():Bool {
        if(_checkingOverlap)
            return false; // prevent infinite recursion

        _checkingOverlap = true;
        FlxG.mouse.getViewPosition(getDefaultCamera(), _mousePos);

        final v:Bool = _mousePos.x > x - ChartEditor.CELL_SIZE && _mousePos.x < x + width && !UIUtil.isHoveringAnyComponent();
        _checkingOverlap = false;
        return v;
    }

    override function destroy():Void {
        if(UIUtil.allComponents.contains(this))
            UIUtil.allComponents.remove(this);

        _mousePos = FlxDestroyUtil.put(_mousePos);
        super.destroy();
    }

    private var _checkingOverlap:Bool = false;
    private var _mousePos:FlxPoint = FlxPoint.get();
}