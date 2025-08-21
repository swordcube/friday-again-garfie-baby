package funkin.backend;

import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;

import openfl.display.Bitmap;
import openfl.display.BitmapData;

import flixel.graphics.FlxGraphic;

/**
 * Basic debug overlay meant for showing warning/error logs
 * on mobile/desktop without opening the game in a terminal.
 */
class DebugOverlay extends Sprite {
    public static var instance(default, null):DebugOverlay;
    public static var messageIcons(default, null):Map<LogLevel, BitmapData>;

    public static function showLog(log:DebugOverlayLogData):Void {
        if(instance == null)
            return;

        @:privateAccess
        final logs = instance.logContainer.__children;

        while(logs.length >= Options.maximumShownLogs)
            instance.logContainer.removeChild(logs[logs.length - 1]);

        final log:DebugOverlayLog = new DebugOverlayLog(log);
        instance.logContainer.addChildAt(log, 0);
        instance.updateLogPositions();
    }

    public var logContainer:Sprite;

    public function new() {
        super();
        instance = this;

        messageIcons = [
            TRACE => FlxG.assets.getBitmapData(Paths.image("ui/images/status/info"), false),
            ERROR => FlxG.assets.getBitmapData(Paths.image("ui/images/status/error"), false),
            WARNING => FlxG.assets.getBitmapData(Paths.image("ui/images/status/warning"), false),
            SUCCESS => FlxG.assets.getBitmapData(Paths.image("ui/images/status/success"), false),
            VERBOSE => FlxG.assets.getBitmapData(Paths.image("ui/images/status/info"), false),
        ];
        logContainer = new Sprite();
        addChild(logContainer);

        visible = #if mobile Options.developerMode #else false #end;
    }

    override function __enterFrame(dt:Float):Void {
        super.__enterFrame(dt);

        final controls:Controls = Controls.instance;
        if(controls.justPressed.DEBUG_OVERLAY)
            visible = !visible;
        
        #if !mobile
        if(visible) {
            graphics.clear();
            graphics.beginFill(0x000000, 0.6);
            graphics.drawRect(0, 0, FlxG.stage.window.width, FlxG.stage.window.height);
            graphics.endFill();
        }
        #else
        visible = Options.developerMode; // TODO: actually match the option's description, i'm just lazy!
        #end
        updateLogPositions();
    }

    public function updateLogPositions():Void {
        @:privateAccess
        final logs = logContainer.__children;

        var y:Float = 0;
        for(i in 0...logs.length) {
            final log:DebugOverlayLog = cast logs[i];
            log.y = y;
            y += log.getBGHeight();
        }
    }
}

typedef DebugOverlayLogData = {
    var type:LogLevel;
    var message:String;
}

class DebugOverlayLog extends Sprite {
    public var bg:Sprite;
    public var icon:Bitmap;
    public var text:TextField;

    public var color:Int;
    public var duration:Float = 3;

    public function getBGHeight():Float {
        final scale:Float = 1;
        final baseHeight:Float = 32 * scale;

        if(text.height + (8 * scale) > baseHeight)
            return text.height + (8 * scale);

        return baseHeight;
    }

    public function new(data:DebugOverlayLogData) {
        super();
        final scale:Float = 1;

        bg = new Sprite();
        addChild(bg);

        icon = new Bitmap(DebugOverlay.messageIcons[data.type]);
        icon.smoothing = true;
        icon.scaleX = icon.scaleY = 0.5 * scale;
        icon.x = 4;
        icon.y = 4;
        addChild(icon);

        text = new TextField();
        text.defaultTextFormat = new TextFormat(FlxG.assets.getFont(Paths.font("fonts/montserrat/semibold")).fontName, Math.round(18 * scale), FlxColor.WHITE);
        text.x = icon.x + icon.width + 8;
        text.text = data.message;
        text.autoSize = LEFT;
        text.wordWrap = true;
        text.width = FlxG.stage.window.width - (text.x + 8);
        text.y = (getBGHeight() - text.height) / 2;
        addChild(text);

        final colorARGB:FlxColor = switch(data.type) {
            case ERROR: FlxColor.RED;
            case WARNING: FlxColor.YELLOW;
            case SUCCESS: FlxColor.LIME;
            case VERBOSE: FlxColor.MAGENTA;
            default: FlxColor.CYAN;
        };
        color = colorARGB.rgb;
    }

    override function __enterFrame(dt:Float):Void {
        super.__enterFrame(dt);
        if(dt > FlxG.maxElapsed * 1000)
            dt = FlxG.maxElapsed * 1000;

        bg.graphics.clear();
        bg.graphics.beginFill(color, 0.6);
        bg.graphics.drawRect(0, 0, FlxG.stage.window.width, getBGHeight());
        bg.graphics.endFill();

        text.width = FlxG.stage.window.width - (text.x + 8);
        text.y = (getBGHeight() - text.height) / 2;
        
        if(DebugOverlay.instance.visible) {
            duration -= dt / 1000;
            if(duration <= 0) {
                duration = 0;
                alpha -= (dt / 1000) * 1.5;
    
                if(alpha <= 0) {
                    DebugOverlay.instance.logContainer.removeChild(this);
                    DebugOverlay.instance.updateLogPositions();
                }
            }
        }
    }
}