package funkin.ui;

import flixel.input.keyboard.FlxKey;

enum abstract ModifierKey(String) from String to String {
    final CTRL = "CTRL";
    final ALT = "ALT";
    final SHIFT = "SHIFT";
    final ANY = "ANY";
}

class UIUtil {
    public static var allComponents:Array<IUIComponent> = [];
    public static var focusedComponents:Array<IUIComponent> = [];

    public static function isHoveringAnyComponent(?ignoreList:Array<IUIComponent>):Bool {
        var c:IUIComponent = null;
        var hasIgnores:Bool = ignoreList != null && ignoreList.length != 0;

        for(i in 0...allComponents.length) {
            c = allComponents[i];
            if(hasIgnores && ignoreList.contains(c))
                continue;

            if(c.checkMouseOverlap())
                return true;
        }
        return false;
    }

    public static function isAnyComponentFocused(?ignoreList:Array<IUIComponent>):Bool {
        var hasIgnores:Bool = ignoreList != null && ignoreList.length != 0;
        if(hasIgnores) {
            var c:IUIComponent = null;
            for(i in 0...focusedComponents.length) {
                c = focusedComponents[i];
                if(ignoreList.contains(c))
                    continue;
                
                return true;
            }
            return false;
        }
        return focusedComponents.length != 0;
    }

    public static function isModifierKeyPressed(mk:ModifierKey):Bool {
        switch(mk) {
            case ModifierKey.CTRL: return #if (mac || macos) FlxG.keys.pressed.WINDOWS #else FlxG.keys.pressed.CONTROL #end;
            case ModifierKey.ALT: return FlxG.keys.pressed.ALT;
            case ModifierKey.SHIFT: return FlxG.keys.pressed.SHIFT;
            case ModifierKey.ANY: return FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.ALT || FlxG.keys.pressed.SHIFT;
        }
    }

    public static function correctModifierKey(key:FlxKey):FlxKey {
        #if (mac || macos)
        switch(key) {
            case CONTROL:
                return WINDOWS;
        }
        #end
        return key;
    }
}