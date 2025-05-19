package funkin.backend;

import flixel.util.FlxSave;

@:build(funkin.backend.macros.OptionsMacro.build())
class Options {
    // GAMEPLAY //
    public static var downscroll:Bool = false;
    public static var centeredNotes:Bool = false;
    public static var useKillers:Bool = true;
    public static var missSounds:Bool = true;
    public static var songOffset:Float = 0;
    public static var hitWindow:Float = 180;
    
    // APPEARANCE //
    public static var antialiasing:Bool = true;
    public static var flashingLights:Bool = true;
    public static var fpsCounter:Bool = true;
    public static var hudType:String = "Classic";
    
    // MISCELLANOUS //
    public static var autoPause:Bool = true;
    public static var verboseLogging:Bool = false;
    public static var multicoreLoading:Bool = false;
    public static var frameRate:Int = 360;

    // GAMEPLAY MODIFIERS //
    @:ignore
    public static var gameplayModifiers:Map<String, Dynamic>;

    @:ignore
    public static var defaultGameplayModifiers:Map<String, Dynamic> = [
        // SCROLL SPEED MODIFIERS //
        "scrollType" => "Multiplicative", // types are Multiplicative, Constant, and XMod
        "scrollSpeed" => 1,
        
        // GENERAL MODIFIERS //
        "practiceMode" => false,
        "botplay" => false,
        "playbackRate" => 1
    ];

    // NOT SHOWN IN OPTIONS MENU, BUT NEEDS TO BE SAVED REGARDLESS //

    public static var contentPackOrder:Array<String> = [];

    @:ignore
    public static var toggledContentPacks:Map<String, Bool>;

    @:ignore
    public static function init():Void {
        _save = new FlxSave();
        _save.bind("options", Constants.SAVE_DIR);

        var doFlush:Bool = false;
        for(key => value in _defaultValues) {
            if(Reflect.field(_save.data, key) == null) {
                doFlush = true;
                Reflect.setField(_save.data, key, value);
            }
        }
        final savedMap:Map<String, Dynamic> = _save.data.gameplayModifiers ?? new Map<String, Dynamic>();
        for (name => value in defaultGameplayModifiers) {
            if(savedMap.get(name) == null) {
                doFlush = true;
                savedMap.set(name, value);
            }
        }
        gameplayModifiers = savedMap;
        toggledContentPacks = _save.data.toggledContentPacks;

        if(toggledContentPacks == null) {
            doFlush = true;
            toggledContentPacks = new Map<String, Bool>();
        }
        if(doFlush)
            save();
        
        FlxG.autoPause = autoPause;
        _lastVolume = FlxG.save.data.volume;
        
        FlxG.signals.focusLost.add(() -> {
            _lastVolume = FlxG.save.data.volume;
            if(!FlxG.autoPause) {
                if(_musicVolTween != null)
                    _musicVolTween.cancel();

                _musicVolTween = FlxTween.tween(FlxG.sound, {volume: _lastVolume * 0.5}, 0.5);
            }
        });
        FlxG.signals.focusGained.add(() -> {
            if(!FlxG.autoPause) {
                if(_musicVolTween != null)
                    _musicVolTween.cancel();

                _musicVolTween = FlxTween.tween(FlxG.sound, {volume: _lastVolume}, 0.5);
            }
        });
        FlxSprite.defaultAntialiasing = true;

        FlxG.allowAntialiasing = antialiasing;
        FlxG.stage.quality = (FlxG.allowAntialiasing) ? BEST : LOW;

        final fps:Int = Options.frameRate;
        if(fps < 10) {
            // unlimited
            FlxG.updateFramerate = 0;
            FlxG.drawFramerate = 0;
        } else {
            // capped
            if(fps > FlxG.drawFramerate) {
                FlxG.updateFramerate = fps;
                FlxG.drawFramerate = fps;
            } else {
                FlxG.drawFramerate = fps;
                FlxG.updateFramerate = fps;
            }
        }
    }
    
    public static function save():Void {
        _save.data.gameplayModifiers = gameplayModifiers;
        _save.data.toggledContentPacks = toggledContentPacks;
        _save.flush();
    }

    //----------- [ Private API ] -----------//

    @:ignore
    private static var _save:FlxSave;

    @:ignore
    private static var _lastVolume:Float = 1;

    @:ignore
    private static var _musicVolTween:FlxTween;
}