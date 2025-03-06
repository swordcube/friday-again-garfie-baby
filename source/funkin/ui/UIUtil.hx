package funkin.ui;

enum abstract ModifierKey(String) from String to String {
    final CTRL = "CTRL";
    final ALT = "ALT";
    final SHIFT = "SHIFT";
    final ANY = "ANY";
}

class UIUtil {
    public static function isModifierKeyPressed(mk:ModifierKey):Bool {
        switch(mk) {
            case ModifierKey.CTRL: return FlxG.keys.pressed.CONTROL;
            case ModifierKey.ALT: return FlxG.keys.pressed.ALT;
            case ModifierKey.SHIFT: return FlxG.keys.pressed.SHIFT;
            case ModifierKey.ANY: return FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.ALT || FlxG.keys.pressed.SHIFT;
        }
    }
}