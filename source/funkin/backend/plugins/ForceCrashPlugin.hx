package funkin.backend.plugins;

import flixel.FlxBasic;

class ForceCrashPlugin extends FlxBasic {
    override function update(elapsed:Float):Void {
        // Force a crash with CTRL+SHIFT+F7, for debugging stuffs
        if(FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F7)
            throw "Forced crash via CTRL+SHIFT+F7";
    }
}