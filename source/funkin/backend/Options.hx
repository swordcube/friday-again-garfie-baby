package funkin.backend;

import flixel.util.FlxSave;

@:build(funkin.backend.macros.OptionsMacro.build())
class Options {
    public static var downscroll:Bool = false;
    public static var centeredNotes:Bool = false;
    public static var useKillers:Bool = true;
    public static var songOffset:Float = 0;
    public static var hitWindow:Float = 180;
    
    public static var antialiasing:Bool = true;
    public static var flashingLights:Bool = true;
    public static var hudType:String = "Classic";
    
    public static var autoPause:Bool = true;
    public static var verboseLogging:Bool = true;

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
        if(doFlush)
            _save.flush();
        
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
        FlxSprite.defaultAntialiasing = antialiasing;
    }
    
    public static function save():Void {
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