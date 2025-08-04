package funkin.ui.dropdown;

import flixel.text.FlxText;
import flixel.util.FlxTimer;

import funkin.ui.panel.CustomPanel;

class DropDownItem extends UIComponent {
    public var dropdown:DropDown;

    public var bg:CustomPanel;
    public var icon:FlxSprite;

    public var label:FlxText;
    public var shortcut:FlxText;

    public var callback:Void->Void;

    public function new(x:Float = 0, y:Float = 0, text:String, shortcutText:String, callback:Void->Void) {
        super(x, y);
        cursorType = POINTER;

        bg = new CustomPanel(0, 0, Paths.image("ui/images/panel_hover"), 32, 22);
        bg.alpha = 0.001;
        add(bg);

        label = new FlxText(20, 2, 0, text);
        label.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        add(label);

        shortcut = new FlxText(20 + (label.width + 30), 2, 0, shortcutText);
        shortcut.setFormat(Paths.font("fonts/montserrat/semibold"), 14, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
        shortcut.alpha = 0.25;
        add(shortcut);

        icon = new FlxSprite(4, 4).makeGraphic(10, 10, FlxColor.TRANSPARENT);
        add(icon);

        this.callback = callback;
    }

    override function update(elapsed:Float) {
        final isHovered:Bool = checkMouseOverlap();
        bg.alpha = FlxMath.lerp(bg.alpha, (isHovered) ? 1 : 0, FlxMath.getElapsedLerp(0.32, elapsed));

        if(Math.abs(bg.alpha) < 0.001)
            bg.alpha = 0;

        if(TouchUtil.justReleased && callback != null && isHovered)
            callback();

        super.update(elapsed);
    }

    override function checkMouseOverlap():Bool {
        _checkingMouseOverlap = true;
        final pointer = TouchUtil.touch;
        final ret:Bool = pointer.overlaps(bg, getDefaultCamera()) && UIUtil.allDropDowns.last() == dropdown;
        _checkingMouseOverlap = false;
        return ret;
    }

    //----------- [ Private API ] -----------//
}