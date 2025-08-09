package funkin.backend;

import openfl.display.Sprite;

/**
 * Basic debug overlay meant for showing warning/error logs
 * on mobile/desktop without opening the game in a terminal.
 */
class DebugOverlay extends Sprite {
    public static var shownLogs:Array<DebugOverlayLog> = [];

    public static function showLog(log:DebugOverlayLog):Void {
        while(shownLogs.length >= Options.maximumShownLogs)
            shownLogs.pop();
        
        shownLogs.insert(0, log);
    }

    public function new() {
        super();
        visible = false;
    }

    override function __enterFrame(dt:Float):Void {
        super.__enterFrame(dt);

        final controls:Controls = Controls.instance;
        if(controls.justPressed.DEBUG_OVERLAY)
            visible = !visible;
        
        final scale:Float = FlxG.stage.window.display.dpi / 96;
        if(visible) {
            graphics.clear();
            graphics.beginFill(0x000000, 0.6);
            graphics.drawRect(0, 0, FlxG.stage.window.width, FlxG.stage.window.height);
            graphics.endFill();
        }
    }
}

typedef DebugOverlayLog = {
    var type:LogLevel;
    var message:String;
}