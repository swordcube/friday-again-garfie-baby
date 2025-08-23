package funkin.ui.menubar;

import flixel.util.FlxDestroyUtil;

class MenuBarDropDownButton extends MenuBarButton {
    public var menuBar:MenuBar;

    override function update(elapsed:Float):Void {
        final hovered:Bool = checkMouseOverlap();
        if(hovered != _hovered) {
            if(hovered && menuBar.dropdown != null) {
                menuBar.dropdown = FlxDestroyUtil.destroy(menuBar.dropdown);
                if(callback != null)
                    callback();
            }
            _hovered = hovered;
        }
        super.update(elapsed);
    }

    //----------- [ Private API ] -----------//

    private var _hovered:Bool = false;
}