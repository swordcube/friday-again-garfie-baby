package funkin.ui.topbar;

import flixel.util.FlxDestroyUtil;

class TopBarDropDownButton extends TopBarButton {
    public var topBar:TopBar;

    override function update(elapsed:Float):Void {
        final hovered:Bool = isHovered();
        if(hovered != _hovered) {
            if(hovered && topBar.dropdown != null) {
                topBar.dropdown = FlxDestroyUtil.destroy(topBar.dropdown);
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