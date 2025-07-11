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

    public static var hitsoundBehavior:String = "Note Hit";
    public static var hitsoundVolume:Float = 0;
    
    // APPEARANCE //
    public static var antialiasing:Bool = true;
    public static var flashingLights:Bool = true;
    public static var fpsCounter:Bool = true;
    public static var intensiveShaders:Bool = true;
    public static var hudType:String = "Classic";
    
    // MISCELLANOUS //
    public static var autoPause:Bool = true;
    public static var verboseLogging:Bool = false;
    public static var multicoreLoading:Bool = false;
    public static var loadingScreen:Bool = true;

    #if LINUX_CASE_INSENSITIVE_FILES
    public static var caseInsensitiveFiles:Bool = true;
    #end

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
        "opponentMode" => false,
        "playbackRate" => 1
    ];

    // CUSTOM OPTIONS //

    @:ignore
    public static var customOptions:Map<String, Map<String, Dynamic>>;

    @:ignore
    public static var customOptionConfigs:Map<String, Array<CustomOption>>;

    @:ignore
    public static var customPages:Map<String, Array<String>>;

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
        customOptions = _save.data.customOptions;

        if(customOptions == null) {
            doFlush = true;
            customOptions = new Map<String, Map<String, Dynamic>>();
        }
        if(doFlush)
            save();

        customPages = new Map<String, Array<String>>();
        customOptionConfigs = new Map<String, Array<CustomOption>>();
        
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
        _save.data.customOptions = customOptions;
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

@:structInit
class CustomOption {
    public var name:String;

    @:optional
    @:default("No description available.")
    public var description:String;

    public var id:String;

    @:optional
    @:jcustomparse(funkin.utilities.DataParse.dynamicValue)
	@:jcustomwrite(funkin.utilities.DataWrite.dynamicValue)
    public var defaultValue:Dynamic;

    public var type:String;

    @:optional
    @:default({})
    @:jcustomparse(funkin.utilities.DataParse.dynamicValue)
	@:jcustomwrite(funkin.utilities.DataWrite.dynamicValue)
    public var params:Dynamic;

    public var page:String;

    @:optional
    @:default(true)
    public var showInMenu:Bool; // just in case you need to add it yourself, for callbacks n shit
}

@:structInit
class CustomOptionsData {
    @:optional
    @:default([])
    public var pages:Array<String>;

    @:optional
    @:default([])
    public var options:Array<CustomOption>;
}