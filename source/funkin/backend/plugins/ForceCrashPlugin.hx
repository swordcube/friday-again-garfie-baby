package funkin.backend.plugins;

import flixel.FlxBasic;

class ForceCrashPlugin extends FlxBasic {
    public function new() {
        super();
        visible = false;
    }
    
    override function update(elapsed:Float):Void {
        // Force a crash with CTRL+SHIFT+F12, for debugging stuffs
        if(FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F12)
            throw "Forced crash via CTRL+SHIFT+F12";
    }
}